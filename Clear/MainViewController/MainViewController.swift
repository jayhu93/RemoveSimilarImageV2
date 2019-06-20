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
import Crashlytics
import Firebase
import NVActivityIndicatorView

class MainViewController: UIViewController {
    
    var viewModel: MainViewModel!

    private var refreshControl = UIRefreshControl()
    @IBOutlet private weak var customActivityIndicatorView: NVActivityIndicatorView!
    @IBOutlet private weak var collectionView: UICollectionView! {
        didSet {
            collectionView.registerNib(forCellType: MainPhotoView.self)
            collectionView.registerNib(forCellType: AdCollectionViewCell.self)
            collectionView.refreshControl = refreshControl
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.apply(input: .viewDidLoad)
        bindViewModel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.apply(input: .viewDidAppear)
    }
    
    private func bindViewModel() {
        refreshControl.reactive.controlEvents(.valueChanged).observeValues { [weak self] _ in
            self?.viewModel.apply(input: .refreshControlAction)
        }

        viewModel.outputSignal.observeValues { [weak self] output in
            guard let strongSelf = self else { return }
            switch output {
            case .reloadData: strongSelf.collectionView.reloadData()
            case .isRefreshing(let isRefreshing):
                if isRefreshing {
                    self?.refreshControl.beginRefreshing()
                    self?.customActivityIndicatorView.startAnimating()
                } else {
                    self?.refreshControl.endRefreshing()
                    self?.customActivityIndicatorView.stopAnimating()
                }
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
        switch viewModel.element(at: indexPath) {
        case .similarSet(let displayModel):
            let cell = collectionView.dequeueReusableCell(withType: MainPhotoView.self, for: indexPath).applied(input: (displayModel, indexPath))
            cell.observe { [weak self] in
                guard let strongSelf = self else { return }
                switch $0 {
                case .removeAll(let indexPath):
                    strongSelf.viewModel.apply(input: .removeAll(indexPath: indexPath))
                case .removeSelected(let indexPath, let selectedIndices):
                    strongSelf.viewModel.apply(input: .removeSelected(indexPath: indexPath, selectedIndices: selectedIndices))
                case .keepAll(let indexPath):
                    strongSelf.viewModel.apply(input: .keepAll(indexPath: indexPath))
                }
            }
            return cell
        case .ad:
            let cell = collectionView.dequeueReusableCell(withType: AdCollectionViewCell.self, for: indexPath).applied(input: ())
            return cell
        }
    }
}

extension MainViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch viewModel.element(at: indexPath) {
        case .similarSet:
            let width = collectionView.frame.width
            let height = width * 1.8
            return CGSize(width: width, height: height)
        case .ad:
            let width = collectionView.frame.width
            let height = width * 1.2
            return CGSize(width: width, height: height)
        }
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
            let crash = UIAlertAction(title: "crash", style: .destructive) { _ in
                Crashlytics.sharedInstance().crash()
            }
            sheet.addAction(removeAllObjects)
            sheet.addAction(dismiss)
            sheet.addAction(printSimilar)
            sheet.addAction(crash)
            self.present(sheet, animated: true, completion: nil)
        }
    }
}
