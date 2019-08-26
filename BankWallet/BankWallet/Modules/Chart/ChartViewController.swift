import UIKit
import ActionSheet

class ChartViewController: ActionSheetController {
    private let delegate: IChartViewDelegate

    private static let diffFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ""
        return formatter
    }()

    private let currentRateItem = ChartCurrentRateItem(tag: 1)
    private let chartRateTypeItem = ChartRateTypeItem(tag: 2)
    private var chartRateItem: ChartRateItem?
    private var marketCapItem = ChartMarketCapItem(tag: 4)

    init(delegate: IChartViewDelegate) {
        self.delegate = delegate
        super.init(withModel: BaseAlertModel(), actionSheetThemeConfig: AppTheme.actionSheetConfig)

        initItems()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initItems() {
        let coin = delegate.coin

        let titleItem = AlertTitleItem(
                title: "chart.title".localized(coin.title),
                icon: UIImage(coin: coin),
                iconTintColor: AppTheme.coinIconColor,
                tag: 0,
                onClose: { [weak self] in
                    self?.dismiss(byFade: false)
                }
        )

        model.addItemView(titleItem)
        model.addItemView(currentRateItem)
        model.addItemView(chartRateTypeItem)

        let chartRateItem = ChartRateItem(tag: 3, chartConfiguration: ChartConfiguration(), indicatorDelegate: self)
        self.chartRateItem = chartRateItem

        model.addItemView(chartRateItem)
        model.addItemView(marketCapItem)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        backgroundColor = .crypto_Dark_Bars
        model.hideInBackground = false

        delegate.viewDidLoad()
    }

    private func show(currentRateValue: CurrencyValue?) {
        guard let currentRateValue = currentRateValue else {
            currentRateItem.bindRate?(nil)
            return
        }
        let formattedValue = ValueFormatter.instance.format(currencyValue: currentRateValue, fractionPolicy: .threshold(high: 1000, low: 0.1), trimmable: false)
        currentRateItem.bindRate?(formattedValue)
    }

    private func show(diff: Decimal) {
        let formatter = ChartViewController.diffFormatter

        let formattedDiff = [formatter.string(from: diff as NSNumber), "%"].compactMap { $0 }.joined()
        currentRateItem.bindDiff?(formattedDiff, !diff.isSignMinus)
    }

    private func show(marketCapValue: CurrencyValue?) {
        guard let marketCapValue = marketCapValue else {
            marketCapItem.setMarketCapText?(nil)
            marketCapItem.setMarketCapTitle?(nil)
            return
        }
        do {
            let marketCapData = try MarketCapFormatter.marketCap(value: marketCapValue.value)
            guard let formattedValue = ValueFormatter.instance.format(currencyValue: CurrencyValue(currency: marketCapValue.currency, value: marketCapData.value)) else {
                marketCapItem.setMarketCapText?(nil)
                marketCapItem.setMarketCapTitle?(nil)
                return
            }

            marketCapItem.setMarketCapText?(formattedValue)
            marketCapItem.setMarketCapTitle?("chart.market_cap".localized)
        } catch {
            marketCapItem.setMarketCapText?(nil)
            marketCapItem.setMarketCapTitle?(nil)
        }
    }

    private func show(type: ChartType, lowValue: CurrencyValue?) {
        marketCapItem.setLowTitle?("chart.low".localized(type.title))

        guard let lowValue = lowValue else {
            marketCapItem.setLowText?(nil)
            return
        }
        let formattedValue = ValueFormatter.instance.format(currencyValue: lowValue, fractionPolicy: .threshold(high: 1000, low: 0.1), trimmable: false)
        marketCapItem.setLowText?(formattedValue)
    }

    private func show(type: ChartType, highValue: CurrencyValue?) {
        marketCapItem.setHighTitle?("chart.high".localized(type.title))

        guard let highValue = highValue else {
            marketCapItem.setHighText?(nil)
            return
        }
        let formattedValue = ValueFormatter.instance.format(currencyValue: highValue, fractionPolicy: .threshold(high: 1000, low: 0.1), trimmable: false)
        marketCapItem.setHighText?(formattedValue)
    }

}

extension ChartViewController: IChartView {

    func show(viewItem: ChartViewItem) {
        show(currentRateValue: viewItem.rateValue)
        show(diff: viewItem.diff)

        chartRateItem?.bind?(viewItem.type, viewItem.points, true)

        show(marketCapValue: viewItem.marketCapValue)
        show(type: viewItem.type, highValue: viewItem.highValue)
        show(type: viewItem.type, lowValue: viewItem.lowValue)
    }

    func addTypeButtons(types: [ChartType]) {
        for type in types {
            chartRateTypeItem.bindButton?(type.title, type.tag) { [weak self] in
                self?.delegate.onSelect(type: type)
            }
        }
    }

    func setChartTypeEnabled(tag: Int) {
    // todo:
    }

    func setChartType(tag: Int) {
        chartRateTypeItem.setSelected?(tag)
    }

    func showSelectedPoint(timestamp: TimeInterval, value: CurrencyValue) {
        let date = Date(timeIntervalSince1970: timestamp)
        let formattedDate = DateHelper.instance.formatTransactionInfoTime(from: date)
        let formattedValue = ValueFormatter.instance.format(currencyValue: value, fractionPolicy: .threshold(high: 1000, low: 0.1), trimmable: false)

        chartRateTypeItem.showPoint?(formattedDate, formattedValue)
    }

    func reloadAllModels() {
        model.reload?()
    }

    func showSpinner() {
        chartRateItem?.showSpinner?()
    }

    func hideSpinner() {
        chartRateItem?.hideSpinner?()
    }

    func show(error: String) {
        chartRateItem?.showError?(error)
    }

}

extension ChartViewController: IChartIndicatorDelegate {

    func didTap(chartPoint: ChartPoint) {
        delegate.chartTouchSelect(point: chartPoint)
    }

    func didFinishTap() {
        chartRateTypeItem.showPoint?(nil, nil)
    }

}
