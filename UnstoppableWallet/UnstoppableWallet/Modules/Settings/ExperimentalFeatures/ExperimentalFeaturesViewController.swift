import UIKit
import SectionsTableView
import ThemeKit
import ComponentKit

class ExperimentalFeaturesViewController: ThemeViewController {
    private let delegate: IExperimentalFeaturesViewDelegate

    private let tableView = SectionsTableView(style: .grouped)

    init(delegate: IExperimentalFeaturesViewDelegate) {
        self.delegate = delegate

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "settings.experimental_features.title".localized

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.registerCell(forClass: HighlightedDescriptionCell.self)
        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.buildSections()
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

}

extension ExperimentalFeaturesViewController: SectionsDataSource {

    private func highlightedDescriptionRow(text: String) -> RowProtocol {
        Row<HighlightedDescriptionCell>(
                id: "alert",
                dynamicHeight: { width in
                    HighlightedDescriptionCell.height(containerWidth: width, text: text)
                },
                bind: { cell, _ in
                    cell.descriptionText = text
                }
        )
    }

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "alert",
                    rows: [
                        highlightedDescriptionRow(text: "settings.experimental_features.description".localized)
                    ]
            ),
            Section(
                    id: "bitcoin_hodling_section",
                    headerState: .margin(height: .margin12),
                    rows: [
                        tableView.titleArrowRow(
                                id: "bitcoin_hodling",
                                title: "settings.experimental_features.bitcoin_hodling".localized,
                                isFirst: true,
                                isLast: true,
                                action: { [weak self] in
                                    self?.delegate.didTapBitcoinHodling()
                                }
                        )
                    ]
            )
        ]
    }

}
