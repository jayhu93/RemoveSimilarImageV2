import UIKit

final class ContainerCollectionViewCell<View: UIView>: UICollectionViewCell {

    private lazy var view: View = View()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(
            [
                view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                view.topAnchor.constraint(equalTo: contentView.topAnchor),
                view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            ]
        )
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ContainerCollectionViewCell: InputAppliable where View: InputAppliable {
    typealias Input = View.Input
    func apply(input: Input) {
        view.apply(input: input)
    }
}
