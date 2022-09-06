import RxSwift
import RxRelay
import MarketKit

class NftCollectionOverviewService {
    let blockchainType: BlockchainType
    private let providerCollectionUid: String
    private let nftMetadataManager: NftMetadataManager
    private let marketKit: MarketKit.Kit
    private var disposeBag = DisposeBag()

    private let stateRelay = PublishRelay<DataStatus<Item>>()
    private(set) var state: DataStatus<Item> = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(blockchainType: BlockchainType, providerCollectionUid: String, nftMetadataManager: NftMetadataManager, marketKit: MarketKit.Kit) {
        self.blockchainType = blockchainType
        self.providerCollectionUid = providerCollectionUid
        self.nftMetadataManager = nftMetadataManager
        self.marketKit = marketKit

        sync()
    }

    private func sync() {
        disposeBag = DisposeBag()

        state = .loading

        Single.zip(
                        nftMetadataManager.collectionMetadataSingle(blockchainType: blockchainType, providerUid: providerCollectionUid),
                        marketKit.nftCollectionStatChartsSingle(blockchainType: blockchainType, providerUid: providerCollectionUid)
                )
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] collection, statCharts in
                    let item = Item(collection: collection, statCharts: statCharts)
                    self?.state = .completed(item)
                }, onError: { [weak self] error in
                    self?.state = .failed(error)
                })
                .disposed(by: disposeBag)
    }

}

extension NftCollectionOverviewService {

    var stateObservable: Observable<DataStatus<Item>> {
        stateRelay.asObservable()
    }

    var blockchain: Blockchain? {
        try? marketKit.blockchain(uid: blockchainType.uid)
    }

    var providerLink: ProviderLink? {
        nftMetadataManager.collectionLink(blockchainType: blockchainType, providerUid: providerCollectionUid)
    }

    func resync() {
        sync()
    }

}

extension NftCollectionOverviewService {

    struct Item {
        let collection: NftCollectionMetadata
        let statCharts: NftCollectionStatCharts?
    }

}
