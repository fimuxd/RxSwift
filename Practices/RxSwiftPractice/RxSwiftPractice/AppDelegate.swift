//
//  AppDelegate.swift
//  RxSwiftPractice
//
//  Created by Bo-Young PARK on 23/01/2018.
//  Copyright © 2018 Bo-Young PARK. All rights reserved.
//

import UIKit


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let viewModel: ViewModel = ViewModelImpl(initialValue: 3)
        
        let rootWindow = UIWindow()
        rootWindow.rootViewController = ViewController().then { $0.bind(viewModel) }
        rootWindow.makeKeyAndVisible()
        
        
        
        self.window = rootWindow
        return true
    }

   


}

