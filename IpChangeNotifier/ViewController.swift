//
//  ViewController.swift
//  IpChangeNotifier
//
//  Created by Christian Schafmeister on 07.07.17.
//  Copyright © 2017 Christian Schafmeister. All rights reserved.
//

import UIKit

class ViewController: UIViewController, IPChangeDetectorDelegate{

    private var detector: IPChangeDetector?
    private var button: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        detector = IPChangeDetector(delegate: self)
        detector?.setInterval(3)

        initUI()
        setupConstraints()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    private func initUI() {
        button = UIButton(type: .roundedRect)
        button.setTitle("Start Detector", for: .normal)
        button.addTarget(self, action: #selector(handleStartDetectorTouched), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
    }

    private func setupConstraints() {
        let constraints: [NSLayoutConstraint] = [
            button.widthAnchor.constraint(equalToConstant: 100),
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ]
        view.addConstraints(constraints)
    }

    @objc
    private func handleStartDetectorTouched(_ button: UIButton) {
        guard let detector = detector else {
            print("ip change detector not initialized!")
            return
        }

        if detector.isRunning() {
            detector.stop()
            button.setTitle("Start Detector", for: .normal)
        } else {
            detector.start()
            button.setTitle("Stop Detector", for: .normal)
        }
    }

    // MARK: IPChangeDetectorDelegate

    func onIPChange() {
        print("ip change!")
    }
}

