//
//  DJIHUDMapView.swift
//  FPVDemo
//
//  Created by xuhao on 2016/11/29.
//  Copyright © 2016年 DJI. All rights reserved.
//

import Foundation
import MapKit
import UIKit
import CoreLocation

class HUDMapView :MKMapView,MKMapViewDelegate
{
    
    var scale = 1.0;
    var homeAnnotation,aircraftAnnotation : MKPointAnnotation?;
    var homePoint : CLLocationCoordinate2D?;
    var aircraftPoint : CLLocationCoordinate2D?;
    var home2aircraftLine : MKPolyline?;
    var timer:Timer?;
    var velx = 0.0;
    var vely = 0.0;
    var yaw = 0.0;
    func initDJIMap()->Void
    {
        self.delegate = self;
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: {_ in
            self.update();
        });
    }
    func update()
    {
        //NSLog("fuckupdate");
        //predict pos
        if (aircraftPoint == nil || !CLLocationCoordinate2DIsValid(aircraftPoint!) )
        {
            
            return;
        }
        moveCenterDraw();
        let lat = (aircraftPoint?.latitude)!;
        let C_EARTH = 6371000.0;
        let londot = vely / (cos(lat / 180.0 * M_PI)*C_EARTH) * 180.0 / M_PI;
        let latdot = velx / C_EARTH * 180.0 / M_PI;
        aircraftPoint?.latitude += latdot * 0.01;
        aircraftPoint?.longitude += londot * 0.01;
    }
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if(overlay is MKPolyline)
        {
            var pr = MKPolylineRenderer(overlay: overlay);
            pr.strokeColor = UIColor.blue.withAlphaComponent(0.5);
            pr.lineWidth = 5;
            return pr;
        }
        return MKPolygonRenderer(overlay:overlay);
    }
   
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "test"
        var anView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId);
        if anView == nil {
            anView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            anView?.canShowCallout = true
        }
        else {
            anView?.annotation = annotation
        }
        if (annotation.title! == "Aircraft")
        {
            anView?.image = UIImage(named: "airplane-icon.png");
        }
        else if (annotation.title! == "Home")
        {
            anView?.image = UIImage(named :"helipad.png");
        }
        anView?.frame.size.height = 40;
        anView?.frame.size.width = 40;
        return anView;
    }
    func moveCenterDraw()
    {
        self.camera.heading = CLLocationDirection(yaw);
        self.camera.centerCoordinate = aircraftPoint!;
        self.camera.altitude = 1000 / scale;
        if ((aircraftAnnotation == nil))
        {
            aircraftAnnotation = MKPointAnnotation();
            aircraftAnnotation?.coordinate = aircraftPoint!;
            aircraftAnnotation?.title = "Aircraft";
            self.addAnnotation(aircraftAnnotation!);
        }else
        {
            aircraftAnnotation?.coordinate = aircraftPoint!;
        }
        if(homePoint == nil || aircraftPoint == nil)
        {
            return;
        }
        let points = [homePoint!,aircraftPoint!];
        if (self.home2aircraftLine != nil)
        {
            self.remove(self.home2aircraftLine!);
        }
        self.home2aircraftLine = MKPolyline(coordinates: points, count: points.count);
        self.add(self.home2aircraftLine!);

    }
    func updateAircraftPosition(local : CLLocationCoordinate2D,Velx:Double,Vely:Double,yaw:Double)
    {
        var pos = local;
        if (!CLLocationCoordinate2DIsValid(local) )
        {
            pos.latitude = 22.578;
            pos.longitude = 113.90;
        }
        
        self.velx = Velx;
        self.vely = Vely;
        self.yaw = yaw;
        aircraftPoint = pos;
        
    }
    
    func updateHomePosition(local : CLLocationCoordinate2D)
    {
        if (!CLLocationCoordinate2DIsValid(local) )
        {
            return;
        }
        homePoint = local;
        if ((homeAnnotation == nil))
        {
            homeAnnotation = MKPointAnnotation();
            homeAnnotation?.coordinate = local;
            homeAnnotation?.title = "Home";
            self.addAnnotation(homeAnnotation!);
        }else
        {
            homeAnnotation?.coordinate = local;
        }
        
    }
}
