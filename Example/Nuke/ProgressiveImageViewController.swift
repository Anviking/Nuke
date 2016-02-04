//
//  ProgressiveImageViewController.swift
//  Nuke Demo
//
//  Created by Alexander Grebenyuk on 04/02/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import Nuke

private let reuseId = "reuseID"

class ProgressiveImageViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    var imageURLs = [
        [NSURL(string: "https://cloud.githubusercontent.com/assets/1567433/9428404/2b0c8f16-49b6-11e5-8f38-f89cae5d9a8f.jpg")!],
        [NSURL(string: "https://cloud.githubusercontent.com/assets/1567433/9428407/3ab53594-49b6-11e5-9ed8-9ccef592826e.jpg")!]
    ]
    var segmentedControl: UISegmentedControl!

    deinit {
        ImageLoaderConfiguration.progressiveImageDecodingEnabled = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        ImageLoaderConfiguration.progressiveImageDecodingEnabled = true

        let segmentedControl = UISegmentedControl(items: ["progressive", "baseline"])
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: Selector("segmentedControlValueChanged"), forControlEvents: .ValueChanged)
        self.segmentedControl = segmentedControl

        self.navigationItem.titleView = segmentedControl

        self.collectionView?.registerClass(ImageCell.self, forCellWithReuseIdentifier: reuseId)
        self.collectionView?.alwaysBounceVertical = false
        self.view.backgroundColor = UIColor.whiteColor()
        self.collectionView?.backgroundColor = self.view.backgroundColor

        let layout = self.collectionViewLayout as! UICollectionViewFlowLayout
        layout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        layout.minimumInteritemSpacing = 8
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseId, forIndexPath: indexPath) as! ImageCell
        cell.backgroundColor = UIColor(white: 235.0 / 255.0, alpha: 1)
        let imageURL = self.currentDataSource[indexPath.row]

        var request = ImageRequest(URL: imageURL, targetSize: ImageMaximumSize, contentMode: .AspectFill)
        request.allowsProgressiveImageDecoding = true

        cell.setImageWith(request)

        return cell
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let layout = self.collectionViewLayout as! UICollectionViewFlowLayout
        let width = (self.view.bounds.size.width - layout.sectionInset.left - layout.sectionInset.right)
        return CGSizeMake(width, width)
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.currentDataSource.count
    }

    var currentDataSource: Array<NSURL> {
        return self.imageURLs[self.segmentedControl.selectedSegmentIndex]
    }

    func segmentedControlValueChanged() {
        self.collectionView?.reloadData()
    }
}


private class ImageCell: UICollectionViewCell {
    private let imageView = UIImageView(frame: CGRectZero)
    private let progressView = UIProgressView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.backgroundColor = UIColor(white: 235.0 / 255.0, alpha: 1)

        self.addSubview(self.imageView)
        self.addSubview(self.progressView)

        self.imageView.translatesAutoresizingMaskIntoConstraints = false
        self.progressView.translatesAutoresizingMaskIntoConstraints = false

        let views = ["imageView": self.imageView, "progressView": self.progressView]

        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|[imageView]|", options: NSLayoutFormatOptions(), metrics: nil, views: views))
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[imageView]|", options: NSLayoutFormatOptions(), metrics: nil, views: views))
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|[progressView]|", options: NSLayoutFormatOptions(), metrics: nil, views: views))
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[progressView(==4)]", options: NSLayoutFormatOptions(), metrics: nil, views: views))
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func setImageWith(URL: NSURL) {
        self.setImageWith(ImageRequest(URL: URL))
    }

    func setImageWith(request: ImageRequest) {
        let task = self.imageView.nk_setImageWith(request)
        task.progressHandler = { [weak self, weak task] _ in
            guard let task = task where task == self?.imageView.nk_imageTask else {
                return
            }
            self?.progressView.setProgress(Float(task.progress.fractionCompleted), animated: true)
            if task.progress.fractionCompleted == 1 {
                UIView.animateWithDuration(0.2) {
                    self?.progressView.alpha = 0
                }
            }
        }
        if task.state == .Completed {
            self.progressView.alpha = 0
        }
    }

    private override func prepareForReuse() {
        super.prepareForReuse()
        self.progressView.progress = 0
        self.progressView.alpha = 1
        self.imageView.image = nil
        self.imageView.nk_cancelLoading()
    }
}
