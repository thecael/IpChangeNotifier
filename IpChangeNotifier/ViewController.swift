//
//  ViewController.swift
//  IpChangeNotifier
//
//  Created by Christian Schafmeister on 07.07.17.
//  Copyright © 2017 Christian Schafmeister. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    private var ifAddresses = [String]()
    private var timer: Timer?
    private var button: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

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
        if timer == nil {
            startIpChangeDetector()
            button.setTitle("Stop Detector", for: .normal)
        } else {
            stopIpChangeDetector()
            button.setTitle("Start Detector", for: .normal)
        }
    }

    private func startIpChangeDetector() {
        if timer != nil {
            print("ip change detector already running")
            return
        }

        print("starting ip change detector")
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            print("checking if addresses ...")
            if self.ifAddresses.isEmpty {
                self.ifAddresses = self.getIFAddresses()
                return
            }

            let newIfAddresses = self.getIFAddresses()
            for address in newIfAddresses where !self.ifAddresses.contains(address) {
                self.ifAddresses = newIfAddresses
                print("ip changed!")
                return
            }
        })
    }

    private func stopIpChangeDetector() {
        print("stopping ip change detector")
        timer?.invalidate()
    }

    private func getIFAddresses() -> [String] {
        var addresses = [String]()
        var ifaddr : UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return [] }
        guard let firstAddr = ifaddr else { return [] }
        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let flags = Int32(ptr.pointee.ifa_flags)
            let addr = ptr.pointee.ifa_addr.pointee

            if (flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING) {
                if addr.sa_family == UInt8(AF_INET) || addr.sa_family == UInt8(AF_INET6) {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if (getnameinfo(ptr.pointee.ifa_addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count),
                                    nil, socklen_t(0), NI_NUMERICHOST) == 0) {
                        let address = String(cString: hostname)
                        addresses.append(address)
                    }
                }
            }
        }

        freeifaddrs(ifaddr)
        return addresses
    }
}

