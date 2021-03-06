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

import SwiftUI

struct TripDetailsView: View {
    @ObservedObject var presenter: TripDetailsPresenter
    var body: some View {
        /*
         The VStack for now holds a TextField for editing the trip name. The navigation bar modifiers define the title using the presenter’s published tripName, so it updates as the user types, and a save button that will persist any changes.
         */
        VStack {
            TextField("Trip Name", text: presenter.setTripName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding([.horizontal])
            presenter.makeMapView()
            Text(presenter.distanceLabel)
            HStack {
                Spacer()
                EditButton()
                Button(action: presenter.addWaypoint, label: {
                    Text("Add")
                })
            }.padding([.horizontal])
            List {
                ForEach(presenter.waypoints, content: presenter.cell)
                    .onMove(perform: { indices, newOffset in
                        presenter.didMoveWaypoint(fromOffsets: indices, toOffset: newOffset)
                    })
                    .onDelete(perform: presenter.didDeleteWaypoint(_:))
            }
        }
        .navigationBarTitle(Text(presenter.tripName), displayMode: .inline)
        .navigationBarItems(trailing: Button("Save", action: presenter.save))
    }
}

struct TripDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        let model = DataModel.sample
        let trip = model.trips[1]
        let mapProvider = RealMapDataProvider()
        let presenter = TripDetailsPresenter(TripDetailsInteractor(trip: trip, model: model, mapInfoProvider: mapProvider))
        return NavigationView {
            TripDetailsView(presenter: presenter)
        }
    }
}
