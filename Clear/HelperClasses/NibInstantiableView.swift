import UIKit

open class NibInstantiableView: UIView {

    public struct Source {
        public let nibName: String
        public let index: Int

        public init(nibName: String, index: Int = 0) {
            self.nibName = nibName
            self.index = index
        }
    }

    @objc public private(set) var nibView: UIView!

    open var source: Source {
        return Source(nibName: String(describing: type(of: self)))
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        instantiateNibView()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        if let view = aDecoder.decodeObject(forKey: #keyPath(nibView)) as? UIView {
            nibView = view
        } else {
            instantiateNibView()
        }
    }

    override open func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(nibView, forKey: #keyPath(nibView))
    }

    private func instantiateNibView() {
        let view = UINib(nibName: source.nibName, bundle: Bundle(for: type(of: self)))
            .instantiate(withOwner: self, options: nil)
            .compactMap { $0 as? UIView }[source.index]

        frame = view.bounds
        insertSubview(view, at: 0)

        nibView = view

        nibView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(
            [
                nibView.topAnchor.constraint(equalTo: topAnchor),
                nibView.leftAnchor.constraint(equalTo: leftAnchor),
                nibView.rightAnchor.constraint(equalTo: rightAnchor),
                nibView.bottomAnchor.constraint(equalTo: bottomAnchor),
            ]
        )
    }
}
