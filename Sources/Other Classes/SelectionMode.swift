//
//  Created by Manuel Vrhovac on 12/06/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//

import Foundation
import Photos

public enum SelectionMode: Equatable {
    
    case single
    case multiple(max: Int)
    public static let multipleUnlimited: SelectionMode = .multiple(max: .max)
    public static var random: SelectionMode { return [.single, .multiple(max: 30)].random! }
    
    var max: Int {
        switch self {
        case .multiple(let max): return max
        default: return 1
        }
    }
    
    var isUnlimited: Bool {
        switch self {
        case .multiple(let max): return max == .max
        default: return false
        }
    }
    
    var isMultipleLimited: Bool {
        return self != .single && !isUnlimited
    }
}
