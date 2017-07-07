//
//  IpChangeDetector.swift
//  IpChangeNotifier
//
//  Created by Christian Schafmeister on 07.07.17.
//  Copyright © 2017 Christian Schafmeister. All rights reserved.
//

import Foundation

protocol IPChangeDetectorDelegate: class {
    func onIPChange()
}

class IPChangeDetector {
    private weak var delegate: IPChangeDetectorDelegate?
    private var addresses = [String]()
    private var interval: TimeInterval = 3
    public var timer: Timer?

    init(delegate: IPChangeDetectorDelegate) {
        self.delegate = delegate
    }

    func start(interval: TimeInterval = 3) {
        if timer != nil {
            print("ip change detector already running")
            return
        }

        setInterval(interval)

        print("starting ip change detector")
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: { _ in
            print("checking if addresses ...")
            if self.addresses.isEmpty {
                self.addresses = self.getAddresses()
                return
            }

            let newIfAddresses = self.getAddresses()
            if !self.checkIfAddressesAreEqual() {
                self.addresses = newIfAddresses
                self.delegate?.onIPChange()
            }
        })
    }

    func stop() {
        print("stopping ip change detector")
        timer?.invalidate()
        timer = nil
    }

    func setInterval(_ interval: TimeInterval) {
        self.interval = interval
    }

    func isRunning() -> Bool {
        return timer != nil
    }

    private func checkIfAddressesAreEqual() -> Bool {
        let newAddresses = self.getAddresses()
        if addresses.count != newAddresses.count {
            return false
        }

        for address in newAddresses where !self.addresses.contains(address) {
            return false
        }

        return true
    }

    // credit for this snippet goes to Martin R on Stackoverflow:
    // https://stackoverflow.com/questions/25626117/how-to-get-ip-address-in-swift/25627545#25627545
    private func getAddresses() -> [String] {
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
