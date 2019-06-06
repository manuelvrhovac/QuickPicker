//
//  StreetFetcher.swift
//  QuickPicker
//
//  Created by Manuel Vrhovac on 06/06/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//

import Foundation
import KVFetcher
import MapKit

/// Fetches iso code ("us", "de", "mx"...") for CLLocation
class CountryFetcher: KVFetcher<CLLocation, String> {
    
    var geocoder = CLGeocoder()
    
    override func _executeFetchValue(for key: Key, completion: ValueCompletion!) {
        geocoder.reverseGeocodeLocation(key) { placemarks, _ in
            guard let placemark = placemarks?.first else {
                print("Geocoder error!")
                return completion(nil)
            }
            guard let country = placemark.isoCountryCode else {
                print("Unknown country!")
                return completion("xx")
            }
            completion?(country)
        }
    }
}

func testCountryFetcher() {
    let countryFetcher = CountryFetcher()
    let barcelona = CLLocation(latitude: 41.3851, longitude: -2.1734)
    
    countryFetcher.fetchValue(for: barcelona) { country in
        guard let country = country else {
            return print("Couldn't fetch country code for Barcelona!")
        }
        print("Barcelona country code is: \(country)")
    }
}

/// Fetches flag image for iso code.
class FlagFetcher: KVFetcher<String, UIImage>.Caching {
    
    override func _executeFetchValue(for key: String, completion: ((UIImage?) -> Void)!) {
        let url = URL(string: "https://www.countryflags.io/\(key)/shiny/64.png")!
        guard let data = try? Data(contentsOf: url) else {
            print("Couldn't fetch data from internet")
            return completion(nil)
        }
        guard let image = UIImage(data: data) else {
            print("Fetched data is not image")
            return completion(nil)
        }
        completion(image)
    }
}

func testFlagFetcher() {
    let flagFetcher = FlagFetcher(cacher: .init(limes: .count(max: 100)))
    
    flagFetcher.fetchValue(for: "de") { flagImage in
        guard let flagImage = flagImage else {
            return print("Couldn't fetch flag image for Germany!")
        }
        print("Got flag image: \(flagImage)!")
    }
}
