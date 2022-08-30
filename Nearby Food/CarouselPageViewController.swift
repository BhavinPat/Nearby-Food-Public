//
//  CarouselPageViewController.swift
//  Nearby Food
//
//
//  See LICENSE folder for this project's licensing information.
//
//  Created by Bhavin Patel on 2/3/22.
//

import Foundation
import UIKit

class CarouselPageViewController: UIPageViewController {
    fileprivate var items: [UIViewController] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        decoratePageControl()
        populateItems()
        if let firstViewController = items.first {
            setViewControllers([firstViewController], direction: .forward, animated: true, completion: nil)
        }
    }
    
    fileprivate func decoratePageControl() {
        let pc = UIPageControl.appearance(whenContainedInInstancesOf: [CarouselPageViewController.self])
        pc.currentPageIndicatorTintColor = .orange
        pc.pageIndicatorTintColor = .gray
    }
    
    fileprivate func populateItems() {
        let text = ["favoriteViewTutorialImages", "filterViewTutorialImages", "mapViewTutorialImages", "nearbyViewTutorialImages", "trymeViewTutorialImages"]
        
        for imageName1 in text {
            let c = createCarouselItemControler(with: imageName1)
            items.append(c)
        }
    }
    
    fileprivate func createCarouselItemControler(with imageName: String) -> UIViewController {
        let c = UIViewController()
        c.view = CarouselItem(withImageName: imageName)

        return c
    }
}

// MARK: - DataSource

extension CarouselPageViewController: UIPageViewControllerDataSource {

    func pageViewController(_: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = items.firstIndex(of: viewController) else {
            return nil
        }
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return items.last
        }
        
        guard items.count > previousIndex else {
            return nil
        }
        
        return items[previousIndex]
    }
    
    func pageViewController(_: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = items.firstIndex(of: viewController) else {
            return nil
        }
        
        let nextIndex = viewControllerIndex + 1
        if nextIndex == 5 {
            NotificationCenter.default.post(name: NSNotification.Name("notificationOneFinalPage"), object: self, userInfo: nil)
        }
        guard items.count != nextIndex else {
            return items.first
        }
        
        guard items.count > nextIndex else {
            return nil
        }
        
        return items[nextIndex]
    }
    
    func presentationCount(for _: UIPageViewController) -> Int {
        return items.count
    }
    
    func presentationIndex(for _: UIPageViewController) -> Int {
        guard let firstViewController = viewControllers?.first,
              let firstViewControllerIndex = items.firstIndex(of: firstViewController) else {
                return 0
        }
        
        return firstViewControllerIndex
    }
}

