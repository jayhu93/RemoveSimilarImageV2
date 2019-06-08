//
//  UIScrollView+Offset.swift
//  Double
//
//  Created by ganzy on 2017/05/13.
//  Copyright © 2017 Mercari. All rights reserved.
//

import UIKit

extension UIScrollView {
    func scrollToTop(animated: Bool) {
        var offset = contentOffset
        offset.y = -adjustedContentInset.top
        setContentOffset(offset, animated: animated)
    }

    func stopScrolling() {
        setContentOffset(contentOffset, animated: false)
    }

    var hasReachedTop: Bool {
        let insetTop: CGFloat
        insetTop = adjustedContentInset.top
        return contentOffset.y <= -insetTop
    }

    var hasReachedBottom: Bool {
        return hasReachedBottom(distance: 0)
    }

    func hasReachedPaginationOffsetY(customThreshold: CGFloat? = nil) -> Bool {
        let threshold: CGFloat
        if let customThreshold = customThreshold {
            threshold = customThreshold
        } else {
            threshold = bounds.width * 4
        }
        return hasReachedBottom(distance: threshold)
    }

    private func hasReachedBottom(distance: CGFloat) -> Bool {
        let insetBottom = adjustedContentInset.bottom
        return contentSize.height <= contentOffset.y + bounds.height - insetBottom + distance
    }

    // MARK: Browse from item detail

    func hasScrolledTo(frame: CGRect) -> Bool {
        return bounds.intersects(frame)
    }
}
