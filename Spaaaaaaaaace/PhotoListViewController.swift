//
//  PhotoListViewController.swift
//  Spaaaaaaaaace
//

import UIKit

class PhotoListCollectionViewFlowLayout: UICollectionViewFlowLayout {
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return true
    }
    
    override func prepareLayout() {
        guard let collectionView = collectionView else { return }
        
        // Full-width in Compact. 3 columns in Regular
        // Note: The size class is often incorrect because this gets called before the trait collection has actually changed
        // This gets called many, many times
        if collectionView.traitCollection.horizontalSizeClass == .Regular {
            let side: CGFloat = floor((collectionView.frame.size.width-30) / 3.0)
            self.itemSize = CGSizeMake(side, side)
        }
        else {
            self.itemSize = CGSizeMake(collectionView.frame.size.width, collectionView.frame.size.width)
        }
    }
    
}

class PhotoCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    
    func set(viewModel: PhotoCellViewModel) {
        dateLabel.text = viewModel.dateString
        imageView.image = UIImage(contentsOfFile: viewModel.photoPath)
    }
}

class DateFormatterHelper {
    static let cellDisplayDateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
    
    static let jsonDateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "y-MM-dd"
        return formatter
    }()
}

class Photo {
    let date: NSDate
    let title: String
    let explanation: String
    let imageSmall: String
    let imageLarge: String
    
    init?(dictionary:[String:String]) {
        guard let date = dictionary["date"], explanation = dictionary["explanation"], title = dictionary["title"] else { return nil }
        self.title = title
        self.explanation = explanation
        if let parsedDate = DateFormatterHelper.jsonDateFormatter.dateFromString(date) {
            self.date = parsedDate
        }
        else {
            return nil
        }
        
        if let small = NSBundle.mainBundle().pathForResource(date, ofType: "jpg"), large = NSBundle.mainBundle().pathForResource(date + "-hd", ofType: "jpg") {
            self.imageSmall = small
            self.imageLarge = large
        }
        else {
            return nil
        }
        

    }
}

struct PhotoCellViewModel {
    let dateString: String
    let photoPath: String
    
    init(photo: Photo) {
        dateString = DateFormatterHelper.cellDisplayDateFormatter.stringFromDate(photo.date)
        photoPath = photo.imageSmall
    }
}

class PhotoListViewController: UICollectionViewController {
    
    var photoList: [Photo] = []
    var viewModels: [PhotoCellViewModel] = []
    let dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let path = NSBundle.mainBundle().pathForResource("stars", ofType: "json")
        let data = NSData(contentsOfFile: path!)
        if let data = data {
            do {
                let items = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0))
                if let items_array = items as? [[String:String]] {
                    
                    photoList = items_array.flatMap({ (dict) -> Photo? in
                        guard let newPhoto = Photo(dictionary: dict) else { return nil }
                        return newPhoto
                    })
                    
                    viewModels = photoList.map({ (photo) -> PhotoCellViewModel in
                        return PhotoCellViewModel(photo: photo)
                    })
                    
                    self.collectionView?.reloadData()
                }
            }
            catch { print("Error loading photos") }
        }
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCell
        
        let cellInfo = viewModels[indexPath.row]
        cell.set(cellInfo)
        
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModels.count
    }
    
    var selectedIndexPath: NSIndexPath?
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        selectedIndexPath = indexPath
        performSegueWithIdentifier("ShowDetail", sender: nil)
    }
    
    ///
    /// The collectionViewLayout WILL be incorrect if both of these methods don't invalidate it
    ///
    override func willTransitionToTraitCollection(newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransitionToTraitCollection(newCollection, withTransitionCoordinator: coordinator)
        self.collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        self.collectionView?.collectionViewLayout.invalidateLayout()
    }
    
}

