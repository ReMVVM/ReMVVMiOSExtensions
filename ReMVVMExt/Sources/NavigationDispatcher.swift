//
//  File.swift
//  
//
//  Created by Paweł Zgoda-Ferchmin on 30/05/2023.
//

import Foundation

final class NavigationDispatcher {
    static let main = NavigationDispatcher()

    let routingQueue = DispatchQueue(label: "RoutingQueue")
    let semaphore = DispatchSemaphore(value: 0)

    let queueingEnabled: Bool = true

    private init() { }

    func async(function: @escaping (@escaping ()-> Void) -> Void) {
        if queueingEnabled {
            routingQueue.async { [weak self] in
                DispatchQueue.main.async { [weak self] in
                    function {
                        self?.semaphore.signal()
                    }
                }
                let waitUntil = DispatchTime.now() + Double(Int64(20 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                let result = self?.semaphore.wait(timeout: waitUntil)
                if case .timedOut = result {
                    print("Navigation stuck on routing")
                }
            }
        } else {
            function { }
        }
    }
}
