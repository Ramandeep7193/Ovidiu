import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class CoinSettingsViewModel {
    private let service: CoinSettingsService
    private let disposeBag = DisposeBag()

    private let openBottomSelectorRelay = PublishRelay<SelectorModule.MultiConfig>()

    private var currentRequest: CoinSettingsService.Request?

    init(service: CoinSettingsService) {
        self.service = service

        subscribe(disposeBag, service.requestObservable) { [weak self] in self?.handle(request: $0) }
    }

    private func handle(request: CoinSettingsService.Request) {
        let config: SelectorModule.MultiConfig

        switch request.type {
        case let .derivation(allDerivations, current):
            config = derivationConfig(token: request.token, allowEmpty: request.allowEmpty, allDerivations: allDerivations, current: current)
        case let .bitcoinCashCoinType(allTypes, current):
            config = bitcoinCashCoinTypeConfig(token: request.token, allowEmpty: request.allowEmpty, allTypes: allTypes, current: current)
        }

        currentRequest = request
        openBottomSelectorRelay.accept(config)
    }

    private func derivationConfig(token: Token, allowEmpty: Bool, allDerivations: [MnemonicDerivation], current: [MnemonicDerivation]) -> SelectorModule.MultiConfig {
        SelectorModule.MultiConfig(
                image: .remote(url: token.coin.imageUrl, placeholder: token.placeholderImageName),
                title: token.coin.code,
                description: "blockchain_settings.description".localized,
                allowEmpty: allowEmpty,
                viewItems: allDerivations.map { derivation in
                    SelectorModule.ViewItem(
                            title: derivation.title,
                            subtitle: derivation.addressType,
                            selected: current.contains(derivation)
                    )
                }
        )
    }

    private func bitcoinCashCoinTypeConfig(token: Token, allowEmpty: Bool, allTypes: [BitcoinCashCoinType], current: [BitcoinCashCoinType]) -> SelectorModule.MultiConfig {
        SelectorModule.MultiConfig(
                image: .remote(url: token.coin.imageUrl, placeholder: token.placeholderImageName),
                title: token.coin.code,
                description: "blockchain_settings.description".localized,
                allowEmpty: allowEmpty,
                viewItems: allTypes.map { type in
                    SelectorModule.ViewItem(
                            title: type.title,
                            subtitle: type.description,
                            selected: current.contains(type)
                    )
                }
        )
    }

}

extension CoinSettingsViewModel {

    var openBottomSelectorSignal: Signal<SelectorModule.MultiConfig> {
        openBottomSelectorRelay.asSignal()
    }

    func onSelect(indexes: [Int]) {
        guard let request = currentRequest else {
            return
        }

        switch request.type {
        case .derivation(let derivations, _):
            service.select(derivations: indexes.map { derivations[$0] }, token: request.token)
        case .bitcoinCashCoinType(let types, _):
            service.select(bitcoinCashCoinTypes: indexes.map { types[$0] }, token: request.token)
        }
    }

    func onCancelSelect() {
        guard let request = currentRequest else {
            return
        }

        service.cancel(token: request.token)
    }

}
