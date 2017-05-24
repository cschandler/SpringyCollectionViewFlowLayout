//
//  SpringyCollectionViewFlowLayout.swift
//  Regal
//
//  Created by Charles Chandler on 5/19/17.
//  Copyright © 2017 Regal Cinemas, Inc. All rights reserved.
//

import UIKit

final class SpringyCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
    private lazy var animator: UIDynamicAnimator = {
        return UIDynamicAnimator(collectionViewLayout: self)
    }()
    
    private var visibleIndexPaths: [IndexPath] = []
    private var lastContentOffset: CGPoint = .zero
    private var lastScrollDelta: CGFloat = 0
    private var lastTouchLocation: CGPoint = .zero
    
    private let scrollPadding: CGFloat = 300.0
    private let scrollRefreshThreshold: CGFloat = 50.0
    private let scrollResistanceCoefficient: CGFloat = 1 / 1500
    private let springDampening: CGFloat = 0.6
    private let springFrequency: CGFloat = 1.0
    
    // MARK: - UICollectionViewLayout
    
    override func prepare() {
        super.prepare()
        
        guard let collectionView = self.collectionView,
            let itemsInCurrentRect = super.layoutAttributesForElements(in: currentRect),
            !shouldReturnOnPrepare else {
                return
        }
        
        lastContentOffset = collectionView.contentOffset
        
        let indexPathsInVisibleRect = itemsInCurrentRect.map { $0.indexPath }
        
        animator.behaviors.forEach { removeIfNeeded(forBehavior: $0, indexPaths: indexPathsInVisibleRect) }
        
        let newVisibleItems = itemsInCurrentRect.filter { !self.visibleIndexPaths.contains($0.indexPath) }
        
        newVisibleItems.forEach { addBehavior(toAttributes: $0) }
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var rect = rect
        rect.size.height += scrollPadding
        rect.origin.y -= scrollPadding
        
        return animator.items(in: rect) as? [UICollectionViewLayoutAttributes]
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return animator.layoutAttributesForCell(at: indexPath) ?? super.layoutAttributesForItem(at: indexPath)
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let collectionView = self.collectionView else {
            return false
        }
        
        lastScrollDelta = newBounds.origin.y - collectionView.bounds.origin.y
        lastTouchLocation = collectionView.panGestureRecognizer.location(in: collectionView)
        
        animator.behaviors.forEach { updateBehavior($0, withLastTouchLocation: lastTouchLocation) }
        
        return false
    }
    
    // MARK: - Helpers
    
    private func adjust(_ spring: UIAttachmentBehavior, centerForTouchPosition touchLocation: CGPoint) {
        guard let item = spring.items.first else {
            return
        }
        
        let distanceFromTouchY = fabs(touchLocation.y - spring.anchorPoint.y)
        let distanceFromTouchX = fabs(touchLocation.x - spring.anchorPoint.x)
        let scrollResistance = (distanceFromTouchX + distanceFromTouchY) * scrollResistanceCoefficient
        
        var center = item.center
        
        if lastScrollDelta < 0 {
            center.y += max(lastScrollDelta, lastScrollDelta * scrollResistance)
        } else {
            center.y += min(lastScrollDelta, lastScrollDelta * scrollResistance)
        }
        
        item.center = center
    }
    
    private func createAttachmentBehavior(withAttributes attributes: UICollectionViewLayoutAttributes) -> UIAttachmentBehavior {
        let spring = UIAttachmentBehavior.init(item: attributes, attachedToAnchor: attributes.center)
        spring.length = 0
        spring.frequency = springFrequency
        spring.damping = springDampening
        spring.action = { [weak spring] in
            guard let spring = spring else {
                return
            }
            
            let delta = fabs(attributes.center.y - spring.anchorPoint.y)
            spring.damping = delta <= 1 ? 100 : self.springDampening
        }
        
        return spring
    }
    
    /// Remove behaviors that are no longer visible
    private func removeIfNeeded(forBehavior behavior: UIDynamicBehavior, indexPaths: [IndexPath]) {
        guard let attachmentBehavior = behavior as? UIAttachmentBehavior,
            let firstBehavior = attachmentBehavior.items.first,
            let attributes = firstBehavior as? UICollectionViewLayoutAttributes,
            !indexPaths.contains(attributes.indexPath) else {
                return
        }
        
        animator.removeBehavior(behavior)
        
        if let index = visibleIndexPaths.index(of: attributes.indexPath) {
            visibleIndexPaths.remove(at: index)
        }
    }
    
    /// Add dynamic behaviors to newly visible attributes.
    private func addBehavior(toAttributes attributes: UICollectionViewLayoutAttributes) {
        let spring = createAttachmentBehavior(withAttributes: attributes)
        
        // If our touch location is not (0,0), we need to adjust our item's center
        if lastScrollDelta != 0 {
            adjust(spring, centerForTouchPosition: lastTouchLocation)
        }
        
        animator.addBehavior(spring)
        visibleIndexPaths.append(attributes.indexPath)
    }
    
    /// Updates the dynamic behavior on layout invalidation.
    private func updateBehavior(_ behavior: UIDynamicBehavior, withLastTouchLocation touchLocation: CGPoint) {
        guard let springBehavior = behavior as? UIAttachmentBehavior,
            let item = springBehavior.items.first else {
                return
        }
        
        adjust(springBehavior, centerForTouchPosition: lastTouchLocation)
        animator.updateItem(usingCurrentState: item)
    }
    
    private var scrollBelowThreshold: Bool {
        guard let contentOffset = self.collectionView?.contentOffset else {
            return true
        }
        
        return fabs(contentOffset.y - lastContentOffset.y) < scrollRefreshThreshold
    }
    
    /// Only refresh the set of UIAttachmentBehaviours if we've moved more than the scroll threshold since last load
    private var shouldReturnOnPrepare: Bool {
        return scrollBelowThreshold && visibleIndexPaths.count > 0
    }
    
    private var currentRect: CGRect {
        guard let collectionView = self.collectionView else {
            return .zero
        }
        
        let y: CGFloat = collectionView.contentOffset.y - scrollPadding
        let height: CGFloat = collectionView.bounds.size.height + scrollPadding
        return CGRect(x: 0, y: y, width: collectionView.bounds.width, height: height)
    }
    
}
