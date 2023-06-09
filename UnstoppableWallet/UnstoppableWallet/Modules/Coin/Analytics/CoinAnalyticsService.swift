import RxSwift
import RxRelay
import MarketKit
import CurrencyKit
import HsToolKit

class CoinAnalyticsService {
    private let fullCoin: FullCoin
    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private var disposeBag = DisposeBag()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(fullCoin: FullCoin, marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit) {
        self.fullCoin = fullCoin
        self.marketKit = marketKit
        self.currencyKit = currencyKit
    }

    private func handle(error: Error) {
        if case let .invalidResponse(statusCode, _) = error as? NetworkManager.RequestError, statusCode == 401 {
            marketKit.analyticsPreviewSingle(coinUid: fullCoin.coin.uid)
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                    .subscribe(onSuccess: { [weak self] analyticsPreview in
                        self?.state = .preview(analyticsPreview)
                    }, onError: { [weak self] error in
                        self?.state = .failed(error)
                    })
                    .disposed(by: disposeBag)
        } else {
            state = .failed(error)
        }
    }

}

extension CoinAnalyticsService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    var currency: Currency {
        currencyKit.baseCurrency
    }

    var coin: Coin {
        fullCoin.coin
    }

    var auditAddresses: [String]? {
        let addresses = fullCoin.tokens.compactMap { token in
            switch (token.blockchainType, token.type) {
            case (.ethereum, .eip20(let address)): return address
            case (.binanceSmartChain, .eip20(let address)): return address
            default: return nil
            }
        }

        return addresses.isEmpty ? nil : addresses
    }

    func blockchains(uids: [String]) -> [Blockchain] {
        do {
            return try marketKit.blockchains(uids: uids)
        } catch {
            return []
        }
    }

    func sync() {
        disposeBag = DisposeBag()

        state = .loading

        return marketKit.analyticsSingle(coinUid: fullCoin.coin.uid, currencyCode: currency.code)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] analytics in
                    self?.state = .success(analytics)
                }, onError: { [weak self] error in
                    self?.handle(error: error)
                })
                .disposed(by: disposeBag)
    }

}

extension CoinAnalyticsService {

    enum State {
        case loading
        case failed(Error)
        case preview(AnalyticsPreview)
        case success(Analytics)
    }

}
