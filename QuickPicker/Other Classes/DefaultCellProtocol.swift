//
//  Created by Manuel Vrhovac on 26/04/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//

import Foundation
import UIKit

/// Get specific type cells (defined by 'Cell' typealias) when getting cells for item, dequeuing cells or registering cells.
///
/// Instead of 'cellForItem()' use 'defaultCellForItem()' as a shortcut to obtain the associated type (typealias) cell. To Dequeue from a storyboard, the cell identifier has to match its class name, and to use 'registerForDefaultCell', the name of .xib file needs to match the class name as well.

protocol DefaultCellProtocol {
    
    associatedtype Cell: UICollectionViewCell
}

extension DefaultCellProtocol where Self: UICollectionView {
    
    var loadedDefaultCells: [Cell] {
        return loadedCells.compactMapAs(Cell.self)
    }
    
    /// Cell .xib name and reuseIdentifier need to be exact same as cell class name.
    func registerForDefaultCell(bundle: Bundle?) {
        let bundle = bundle ?? Bundle.main
        let id = Cell.selfID
        register(.init(nibName: id, bundle: bundle), forCellWithReuseIdentifier: id)
    }
    
    func defaultCellForItem(at indexPath: IndexPath) -> Cell? {
        return cellForItem(at: indexPath) as? Cell
    }
    
    func dequeueReusableDefaultCell(at indexPath: IndexPath) -> Cell? {
        return dequeueReusableCell(withReuseIdentifier: Cell.selfID, for: indexPath) as? Cell
    }
    
    func defaultCellForItem(at location: CGPoint) -> Cell? {
        guard let ip = indexPathForItem(at: location) else { return nil }
        return defaultCellForItem(at: ip)
    }
}
