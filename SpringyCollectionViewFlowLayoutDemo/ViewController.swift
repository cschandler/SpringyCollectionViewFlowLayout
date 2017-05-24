//
//  ViewController.swift
//  SpringyCollectionViewFlowLayoutDemo
//
//  Created by Charles Chandler on 5/24/17.
//  Copyright © 2017 Charles Chander. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var collectionView: UICollectionView! {
        didSet {
            collectionView.delegate = self
            collectionView.dataSource = self
            collectionView.backgroundColor = .white
            view.addSubview(collectionView)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let flowLayout = SpringyCollectionViewFlowLayout()
        flowLayout.minimumInteritemSpacing = 10
        flowLayout.minimumLineSpacing = 10
        flowLayout.itemSize = CGSize(width: 44, height: 44)
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        
        collectionView.register(Cell.self, forCellWithReuseIdentifier: "Cell")
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1000
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
            
        cell.backgroundColor = .orange
        cell.alpha = 0.0
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        UIView.animate(withDuration: 0.3) { 
            cell.alpha = 1.0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        cell.alpha = 0.0
    }
    
}

class Cell: UICollectionViewCell {}
