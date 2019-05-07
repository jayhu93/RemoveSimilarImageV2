/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Contains the application's delegate.
*/

import UIKit
import Swinject

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private lazy var viewModel = Container.sharedResolver.resolve(AppDelegateViewModelType.self)!

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        bindViewModel()
        viewModel.inputs.application(application, didFinishLaunchingWithOptions: launchOptions)
        return true
    }
    
    private func bindViewModel() {
        viewModel.outputs.setupUISignal.observeValues { [weak self] in
            self?.setupUI()
        }
    }
    
    private func setupUI() {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = MainViewController.make()
        window.makeKeyAndVisible()
        self.window = window
    }
    
}
