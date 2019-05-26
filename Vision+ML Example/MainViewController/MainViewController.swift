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
import ReactiveCocoa

class MainViewController: UIViewController {
    
    var viewModel: MainViewModel!

    private var refreshControl = UIRefreshControl()
    
    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.registerNib(forCellType: MainPhotoView.self)
            collectionView.refreshControl = refreshControl
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.apply(input: .viewDidLoad)
        bindViewModel()
    }
    
    private func bindViewModel() {
        refreshControl.reactive.controlEvents(.valueChanged).observeValues { [weak self] _ in
            self?.viewModel.apply(input: .refreshControlAction)
        }

        viewModel.outputSignal.observeValues { [weak self] output in
            guard let strongSelf = self else { return }
            switch output {
            case .reloadData: strongSelf.collectionView.reloadData()
            }
        }
    }

}

// MARK: UICollectionViewDataSource

extension MainViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModel.numberOfSections()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfElements(inSection: section)
    }
}

// MARK: UICollectionViewDelegate

extension MainViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let displayModel = viewModel.element(at: indexPath)
        let cell = collectionView.dequeueReusableCell(withType: MainPhotoView.self, for: indexPath).applied(input: (displayModel, indexPath))
        cell.observe { [weak self] in
            guard let strongSelf = self else { return }
            switch $0 {
            case .removeAll(let indexPath):
                strongSelf.viewModel.apply(input: .removeAll(indexPath: indexPath))
            case .removeSelected(let indexPath):
                strongSelf.viewModel.apply(input: .removeSelected(indexPath: indexPath))
            case .keepAll(let indexPath):
                strongSelf.viewModel.apply(input: .keepAll(indexPath: indexPath))
            case .markDelete(let indexPath, let photoIndex, let isOn):
                strongSelf.viewModel.apply(input: .markDelete(indexPath: indexPath, photoIndex: photoIndex, isOn: isOn))
            }
        }
        return cell
    }
}

extension MainViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width
        let height = width * 1.4
        return CGSize(width: width, height: height)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.hasReachedPaginationOffsetY() {
            viewModel.apply(input: .reachedPaginationOffsetY)
        }
    }
}

// MARK: Shake devide

extension MainViewController {
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            // Present debug menu
            let sheet = UIAlertController(title: "Debug Menu", message: "", preferredStyle: .actionSheet)
            let removeAllObjects = UIAlertAction(title: "Remove all objs", style: .default) { [weak self] (_) in
                self?.viewModel.apply(input: .removeAllObjs)
            }
            let dismiss = UIAlertAction(title: "Dismiss", style: .default) { (_) in
                sheet.dismiss(animated: true, completion: nil)
            }
            let printSimilar = UIAlertAction(title: "Print Simialr PhotoObjects", style: .default) { [weak self] (_) in
                self?.viewModel.apply(input: .printSimilarPhotoObjects)
            }
            sheet.addAction(removeAllObjects)
            sheet.addAction(dismiss)
            sheet.addAction(printSimilar)
            self.present(sheet, animated: true, completion: nil)
        }
    }
}
