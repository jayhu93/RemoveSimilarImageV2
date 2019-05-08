/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View controller for selecting images and applying Vision + Core ML processing.
*/

import UIKit
import CoreML
import Vision
import ImageIO
import Swinject
import ReactiveSwift
import Result

class MainViewController: UIViewController {
    
    var viewModel: MainViewModelType!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
        viewModel.inputs.viewDidLoad()
        collectionView.registerClass(forCellType: ContainerCollectionViewCell<MainPhotoView>.self)
    }
    
    private func bindViewModel() {
        viewModel.outputs.reloadSignal.observeValues { [weak self] in
            self?.collectionView.reloadData()
        }
    }

}

// MARK: UICollectionViewDataSource

extension MainViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModel.outputs.numberOfSections()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.outputs.numberOfElements(section)
    }
}

// MARK: UICollectionViewDelegate

extension MainViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let photoObject = viewModel.outputs.element(at: indexPath)
        return collectionView.dequeueReusableCell(withType: ContainerCollectionViewCell<MainPhotoView>.self, for: indexPath).applied(input: photoObject)
    }
}

extension MainViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width - (12 * 2)
        let height = width * 1.4
        return CGSize(width: width, height: height)
    }
}

// MARK: Shake devide

extension MainViewController {
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            // Present debug menu
            let sheet = UIAlertController(title: "Debug Menu", message: "", preferredStyle: .actionSheet)
            let removeAllObjects = UIAlertAction(title: "Remove all objs", style: .default) { [weak self] (_) in
                self?.viewModel.inputs.removeAllObjs()
            }
            let dismiss = UIAlertAction(title: "Dismiss", style: .default) { (_) in
                sheet.dismiss(animated: true, completion: nil)
            }
            let printSimilar = UIAlertAction(title: "Print Simialr PhotoObjects", style: .default) { [weak self] (_) in
                self?.viewModel.inputs.printSimilarPhotoObjects()
            }
            sheet.addAction(removeAllObjects)
            sheet.addAction(dismiss)
            sheet.addAction(printSimilar)
            self.present(sheet, animated: true, completion: nil)
        }
    }
}
