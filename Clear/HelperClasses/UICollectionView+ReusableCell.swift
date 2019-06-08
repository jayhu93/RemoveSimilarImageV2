import UIKit

extension UICollectionView {
    func registerNib<T: UICollectionViewCell>(forCellType type: T.Type) {
        let name = String(describing: type)
        let nib = UINib(nibName: name, bundle: nil)
        register(nib, forCellWithReuseIdentifier: name)
    }

    func registerNib<T: UIView>(forSupplementaryViewOfKind elementKind: String, withType type: T.Type) {
        let name = String(describing: type)
        let nib = UINib(nibName: name, bundle: nil)
        register(nib, forSupplementaryViewOfKind: elementKind, withReuseIdentifier: name)
    }

    func registerClass<T: UICollectionViewCell>(forCellType type: T.Type) {
        register(T.self, forCellWithReuseIdentifier: String(describing: type))
    }

    func registerClass<T: UIView>(forSupplementaryViewOfKind elementKind: String, withType type: T.Type) {
        register(T.self, forSupplementaryViewOfKind: elementKind, withReuseIdentifier: String(describing: type))
    }

    func dequeueReusableCell<T: UICollectionViewCell>(withType type: T.Type, for indexPath: IndexPath) -> T {
        if let cell = dequeueReusableCell(withReuseIdentifier: String(describing: type), for: indexPath) as? T {
            return cell
        } else {
            fatalError("no reusable cell: \(type)")
        }
    }

    func dequeueReusableSupplementaryView<T: UIView>(ofKind elementKind: String, withType type: T.Type, for indexPath: IndexPath) -> T {
        if let supplementaryView = dequeueReusableSupplementaryView(ofKind: elementKind, withReuseIdentifier: String(describing: type), for: indexPath) as? T {
            return supplementaryView
        } else {
            fatalError("no reusable supplementary view: \(type)")
        }
    }
}
