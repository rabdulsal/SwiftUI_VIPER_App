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
import SwiftUI
import Combine

class TripDetailsPresenter: ObservableObject {
    private let interactor: TripDetailsInteractor
    private let router: TripDetailsRouter
    private var cancellables = Set<AnyCancellable>()
    @Published var tripName: String="No name"
    @Published var distanceLabel: String="Calculating..."
    @Published var waypoints = [Waypoint]()
    let setTripName: Binding<String>
    
    init(_ interactor: TripDetailsInteractor) {
        self.interactor = interactor
        self.router = TripDetailsRouter(interactor.mapInfoProvider)
        /* 1.
         Create a binding to set the trip name. The TextField will use this in the view to be able to read and write from the value.
        */
        setTripName = Binding<String>(
            get: { interactor.tripName },
            set: { interactor.setTripName($0) }
        )
        /* 2.
         Assign the trip name from the interactor’s publisher to the tripName property of the presenter. This keeps the value synchronized.
         */
        interactor.tripNamePublisher
            .assign(to: \.tripName, on: self)
            .store(in: &cancellables)
        
        /*
         The first subscription takes the raw distance from the interactor and formats it for display in the view, and the second just copies over the waypoints.
         */
        interactor.$totalDistance
            .map { "Total Distance: " + MeasurementFormatter().string(from: $0)
            }
            .replaceNil(with: "Calculating...")
            .assign(to: \.distanceLabel, on: self)
            .store(in: &cancellables)
        
        interactor.$waypoints
            .assign(to: \.waypoints, on: self)
            .store(in: &cancellables)
    }
    
    func makeMapView() -> some View { TripMapView(presenter: TripMapViewPresenter(interactor)) }
    
    func save() { interactor.save() }
    
    func addWaypoint() {
      interactor.addWaypoint()
    }

    func didMoveWaypoint(fromOffsets: IndexSet, toOffset: Int) {
      interactor.moveWaypoint(fromOffsets: fromOffsets, toOffset: toOffset)
    }

    func didDeleteWaypoint(_ atOffsets: IndexSet) {
      interactor.deleteWaypoint(atOffsets: atOffsets)
    }
    
    // calls the router to get a waypoint view for the waypoint and put it in a NavigationLink.
    func cell(for waypoint: Waypoint) -> some View {
      let destination = router.makeWaypointView(for: waypoint)
        .onDisappear(perform: interactor.updateWaypoints)
      return NavigationLink(destination: destination) {
        Text(waypoint.name)
      }
    }

}
