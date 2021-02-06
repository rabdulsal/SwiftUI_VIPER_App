/// Copyright (c) 2021 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation
import Combine
import MapKit

class TripDetailsInteractor {
    @Published var totalDistance: Measurement<UnitLength>=Measurement(value: 0, unit: .meters)
    @Published var waypoints: [Waypoint]=[]
    @Published var directions: [MKRoute]=[]
    private let trip: Trip
    private let model: DataModel
    let mapInfoProvider: MapDataProvider
    private var cancellables = Set<AnyCancellable>()
    var tripName: String { trip.name } // This exposes just the String version of the trip name
    var tripNamePublisher: Published<String>.Publisher { trip.$name } // Publisher for when that name changes.
    
    init(trip: Trip, model: DataModel, mapInfoProvider: MapDataProvider) {
        self.trip = trip;self.model = model;self.mapInfoProvider=mapInfoProvider
        
        /*
         The first is just a copy to the interactor’s waypoint list. The second uses the mapInfoProvider to calculate the total distance for all of the waypoints. And the third uses the same data provider to get directions between the waypoints.

         The presenter then uses these values to provide information to the user.
         */
        // 1.
        trip.$waypoints
            .assign(to: \.waypoints, on: self)
            .store(in: &cancellables)
        // 2.
        trip.$waypoints
            .flatMap { mapInfoProvider.totalDistance(for: $0) }
            .map { Measurement(value: $0, unit: UnitLength.meters) }
            .assign(to: \.totalDistance, on: self)
            .store(in: &cancellables)
        // 3.
        trip.$waypoints
            .setFailureType(to: Error.self)
            .flatMap { mapInfoProvider.directions(for: $0) }
            .catch { _ in Empty<[MKRoute], Never>() }
            .assign(to: \.directions, on: self)
            .store(in: &cancellables)
    }
    
    func setTripName(_ name: String) {
        trip.name = name
    }
    
    func save() {
        model.save()
    }
    
    func addWaypoint() { trip.addWaypoint() }
    
    func moveWaypoint(fromOffsets: IndexSet, toOffset: Int) {
        trip.waypoints.move(fromOffsets: fromOffsets, toOffset: toOffset)
    }
    
    func deleteWaypoint(atOffsets: IndexSet) { trip.waypoints.remove(atOffsets: atOffsets) }
    
    func updateWaypoints() { trip.waypoints = trip.waypoints }
}
