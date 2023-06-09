import UIKit
import ThemeKit
import ComponentKit
import SectionsTableView

protocol IBottomSheetDismissDelegate: AnyObject {
    func bottomSelectorOnDismiss()
}

class BottomSheetModule {

    static func viewController(image: BottomSheetTitleView.Image? = nil, title: String, subtitle: String? = nil, items: [Item] = [], buttons: [Button] = [], delegate: IBottomSheetDismissDelegate? = nil) -> UIViewController {
        let viewController = BottomSheetViewController(image: image, title: title, subtitle: subtitle, items: items, buttons: buttons, delegate: delegate)
        return viewController.toBottomSheet
    }

}

extension BottomSheetModule {

    static func copyConfirmation(value: String) -> UIViewController {
        viewController(
                image: .local(image: UIImage(named: "warning_2_24")?.withTintColor(.themeJacob)),
                title: "copy_warning.title".localized,
                items: [
                    .highlightedDescription(text: "copy_warning.description".localized)
                ],
                buttons: [
                    .init(style: .red, title: "copy_warning.i_will_risk_it".localized) {
                        UIPasteboard.general.string = value
                        HudHelper.instance.show(banner: .copied)
                    },
                    .init(style: .transparent, title: "copy_warning.dont_copy".localized)
                ]
        )
    }

    static func backupPrompt(account: Account, sourceViewController: UIViewController?) -> UIViewController {
        viewController(
                image: .local(image: UIImage(named: "warning_2_24")?.withTintColor(.themeJacob)),
                title: "backup_prompt.title".localized,
                items: [
                    .highlightedDescription(text: "backup_prompt.warning".localized)
                ],
                buttons: [
                    .init(style: .yellow, title: "backup_prompt.backup".localized, actionType: .afterClose) { [weak sourceViewController] in
                        guard let viewController = BackupModule.viewController(account: account) else {
                            return
                        }

                        sourceViewController?.present(viewController, animated: true)
                    },
                    .init(style: .transparent, title: "backup_prompt.later".localized)
                ]
        )
    }

    static func description(title: String, text: String) -> UIViewController {
        viewController(
                image: .local(image: UIImage(named: "circle_information_20")?.withTintColor(.themeGray)),
                title: title,
                items: [
                    .description(text: text)
                ]
        )
    }

}

extension BottomSheetModule {

    enum Item {
        case description(text: String)
        case highlightedDescription(text: String)
        case copyableValue(title: String, value: String)
        case contractAddress(imageUrl: String, value: String, explorerUrl: String?)
    }

    struct Button {
        let style: PrimaryButton.Style
        let title: String
        let actionType: ActionType
        let action: (() -> ())?

        init(style: PrimaryButton.Style, title: String, actionType: ActionType = .regular, action: (() -> ())? = nil) {
            self.style = style
            self.title = title
            self.actionType = actionType
            self.action = action
        }

        enum ActionType {
            case regular
            case afterClose
        }
    }

}
