//
//  ARCetvelViewController.swift
//  Cetvel
//
//  Created by Kurtulus Ahmet on 16.12.2017.
//  Copyright © 2017 Kurtulus Ahmet. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Photos
import AudioToolbox
import VideoToolbox
import SnapKit
import LiquidFloatingActionButton

class ARCetvelViewController: UIViewController, LiquidFloatingActionButtonDataSource, LiquidFloatingActionButtonDelegate {
    
    private let sceneView: ARSCNView =  ARSCNView(frame: UIScreen.main.bounds)
    private let indicator = UIImageView()
    private let resultLabel = UILabel().then({
        $0.textAlignment = .center
        $0.textColor = UIColor.black
        $0.numberOfLines = 0
        $0.font = UIFont.systemFont(ofSize: 10, weight: UIFont.Weight.heavy)
    })
    
    var cells: [LiquidFloatingCell] = []
    var floatingActionButton: LiquidFloatingActionButton!
    
    private var line: LineNode?
    private var lineSet: LineSetNode?
    private var lines: [LineNode] = []
    private var lineSets: [LineSetNode] = []
    private var planes = [ARPlaneAnchor: Plane]()
    private var focusSquare: FocusSquare?
    private var mode = MeasurementMode.length
    private var finishButtonState = false
    private var lastState: ARCamera.TrackingState = .notAvailable {
        didSet {
            switch lastState {
            case .notAvailable:
                guard HUD.isVisible else { return }
                HUD.show(title: "AR not available")
            case .limited(let reason):
                switch reason {
                case .initializing:
                    HUD.show(title: "Cetvel başlatılıyor", message: "Lütfen daha fazla nokta keşfetmek için cihazınızı sallayınız", inSource: self, autoDismissDuration: nil)
                case .insufficientFeatures:
                    HUD.show(title: "Bilgi yetersiz", message: "Özellik noktası yeterli değildir, lütfen daha fazla özellik noktası elde etmek için cihazı sallayın", inSource: self, autoDismissDuration: 5)
                case .excessiveMotion:
                    HUD.show(title: "Aşırı Hareket", message: "Cihaz çok hızlı hareket ediyor", inSource: self, autoDismissDuration: 5)
                }
            case .normal:
                HUD.dismiss()
            }
        }
    }
    
    private var measureUnit = ApplicationSetting.Status.defaultUnit {
        didSet {
            let v = measureValue
            measureValue = v
        }
    }
    
    private var measureValue: MeasurementUnit? {
        didSet {
            if let m = measureValue {
                resultLabel.text = nil
                resultLabel.attributedText = m.attributeString(type: measureUnit)
            } else {
                resultLabel.attributedText = mode.toAttrStr()
            }
        }
    }
    
    private let placeButton = UIButton(size: CGSize(width: 80, height: 80), image: Image.Place.length)
    private let cancleButton = UIButton(size: CGSize(width: 60, height: 60), image: Image.Close.delete)
    private let finishButton = UIButton(size: CGSize(width: 60, height: 60), image: Image.Place.done)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        layoutViewController()
        setupFocusSquare()
        Sound.install()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        restartSceneView()
    }
    
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    private func layoutViewController() {
        let width = view.bounds.width
        let height = view.bounds.height
        view.backgroundColor = UIColor.black
        
        do {
            view.addSubview(sceneView)
            sceneView.frame = view.bounds
            sceneView.delegate = self
        }
        do {
            let resultLabelBg = UIView()
            resultLabelBg.backgroundColor = UIColor.white.withAlphaComponent(0.6)
            resultLabelBg.clipsToBounds = true
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(ARCetvelViewController.changeMeasureUnitAction(_:)))
            resultLabel.addGestureRecognizer(tap)
            resultLabel.isUserInteractionEnabled = true
            
            resultLabelBg.frame = CGRect(x: 0, y: 0, width: width, height: 90)
            resultLabel.frame = resultLabelBg.frame.insetBy(dx: 10, dy: 0)
            resultLabel.attributedText = mode.toAttrStr()
            
            view.addSubview(resultLabelBg)
            view.addSubview(resultLabel)
        }
        
        do {
            indicator.image = Image.Indicator.disable
            view.addSubview(indicator)
            indicator.frame = CGRect(x: (width - 60)/2, y: (height - 60)/2, width: 60, height: 60)
        }
        do {
            view.addSubview(finishButton)
            view.addSubview(placeButton)
            finishButton.addTarget(self, action: #selector(ARCetvelViewController.finishAreaAction(_:)), for: .touchUpInside)
            placeButton.addTarget(self, action: #selector(ARCetvelViewController.placeAction(_:)), for: .touchUpInside)
            placeButton.frame = CGRect(x: (width - 80)/2, y: (height - 20 - 80), width: 80, height: 80)
            finishButton.center = placeButton.center
        }
        do {
            view.addSubview(cancleButton)
            cancleButton.addTarget(self, action: #selector(ARCetvelViewController.deleteAction(_:)), for: .touchUpInside)
            cancleButton.frame = CGRect(x: 12, y: self.view.frame.height - 56 - 16, width: 60, height: 60)
        }
        do {
            let createButton: (CGRect, LiquidFloatingActionButtonAnimateStyle) -> LiquidFloatingActionButton = { (frame, style) in
                let floatingActionButton = CustomDrawingActionButton(frame: frame)
                floatingActionButton.animateStyle = style
                floatingActionButton.dataSource = self
                floatingActionButton.delegate = self
                return floatingActionButton
            }
            
            let cellFactory: (String) -> LiquidFloatingCell = { (iconName) in
                let cell = LiquidFloatingCell(icon: UIImage(named: iconName)!)
                return cell
            }
            
            cells.append(cellFactory("setting"))
            cells.append(cellFactory("shape"))
            cells.append(cellFactory("save"))
            cells.append(cellFactory("result"))
            cells.append(cellFactory("area"))
            
            let floatingFrame = CGRect(x: self.view.frame.width - 56 - 16, y: self.view.frame.height - 56 - 16, width: 60, height: 60)
            let bottomRightButton = createButton(floatingFrame, .up)
            
            let image = UIImage(named: "more_off")
            bottomRightButton.image = image
            
            self.view.addSubview(bottomRightButton)
        }
    }
    
    func numberOfCells(_ liquidFloatingActionButton: LiquidFloatingActionButton) -> Int {
        return cells.count
    }
    
    func cellForIndex(_ index: Int) -> LiquidFloatingCell {
        return cells[index]
    }
    
    func liquidFloatingActionButton(_ liquidFloatingActionButton: LiquidFloatingActionButton, didSelectItemAtIndex index: Int) {
        
        if index == 0 {
            moreAction()
        }else if index == 1 {
            restartAction()
        }else if index == 2 {
            saveImage()
        }else if index == 3 {
            copyAction()
        }else if index == 4 {
            changeMeasureMode(index: index)
        }
        liquidFloatingActionButton.close()
    }
    
    private func configureObserver() {
        func cleanLine() {
            line?.removeFromParent()
            line = nil
            for node in lines {
                node.removeFromParent()
            }
            
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationDidEnterBackground, object: nil, queue: OperationQueue.main) { _ in
            cleanLine()
        }
    }
    
    deinit {
        Sound.dispose()
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Target Action
@objc private extension ARCetvelViewController {
    
    func saveImage() {
        func saveImage(image: UIImage) {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { (isSuccess: Bool, error: Error?) in
                if let e = error {
                    HUD.show(title: "Kayıt başarısız", message: e.localizedDescription)
                } else{
                    HUD.show(title: "Kayıt başarılı")
                }
            }
        }
        
        let image = sceneView.snapshot()
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            saveImage(image: image)
        default:
            PHPhotoLibrary.requestAuthorization { (status) in
                switch status {
                case .authorized:
                    saveImage(image: image)
                default:
                    HUD.show(title: "Kayıt başarısız", message: "Lütfen albüm izinlerini Ayarlar'dan açın")
                }
            }
        }
    }
    
    func placeAction(_ sender: UIButton) {
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [.allowUserInteraction,.curveEaseOut], animations: {
            sender.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }) { (value) in
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [.allowUserInteraction,.curveEaseIn], animations: {
                sender.transform = CGAffineTransform.identity
            }) { (value) in
            }
        }
        Sound.play()
        switch mode {
        case .length:
            if let l = line {
                lines.append(l)
                line = nil
            } else  {
                let startPos = sceneView.worldPositionFromScreenPosition(indicator.center, objectPos: nil)
                if let p = startPos.position {
                    line = LineNode(startPos: p, sceneV: sceneView)
                }
            }
        case .area:
            if let l = lineSet {
                l.addLine()
            } else {
                let startPos = sceneView.worldPositionFromScreenPosition(indicator.center, objectPos: nil)
                if let p = startPos.position {
                    lineSet = LineSetNode(startPos: p, sceneV: sceneView)
                }
            }
        }
    }
    
    func restartAction() {
        line?.removeFromParent()
        line = nil
        for node in lines {
            node.removeFromParent()
        }
        
        lineSet?.removeFromParent()
        lineSet = nil
        for node in lineSets {
            node.removeFromParent()
        }
        restartSceneView()
        measureValue = nil
    }
    
    func deleteAction(_ sender: UIButton) {
        switch mode {
        case .length:
            if line != nil {
                line?.removeFromParent()
                line = nil
            } else if let lineLast = lines.popLast() {
                lineLast.removeFromParent()
            } else {
                lineSets.popLast()?.removeFromParent()
            }
        case .area:
            if let ls = lineSet {
                if !ls.removeLine() {
                    lineSet = nil
                }
            } else if let lineSetLast = lineSets.popLast() {
                lineSetLast.removeFromParent()
            } else {
                lines.popLast()?.removeFromParent()
            }
        }
        cancleButton.normalImage = Image.Close.delete
        measureValue = nil
    }
    
    func copyAction() {
        UIPasteboard.general.string = resultLabel.text
        HUD.show(title: "Panoya kopyalandı")
    }
    
    func moreAction() {
        guard let vc = UIStoryboard(name: "Settings", bundle: nil).instantiateInitialViewController() else {
            print("sıkıntı")
            return
        }
        present(vc, animated: true, completion: nil)
    }
    
    func finishAreaAction(_ sender: UIButton) {
        guard mode == .area,
            let line = lineSet,
            line.lines.count >= 2 else {
                lineSet = nil
                return
        }
        lineSets.append(line)
        lineSet = nil
        changeFinishState(state: false)
    }
    
    func changeFinishState(state: Bool) {
        guard finishButtonState != state else { return }
        finishButtonState = state
        var center = placeButton.center
        if state {
            center.y -= 100
        }
        UIView.animate(withDuration: 0.3) {
            self.finishButton.center = center
        }
    }
    
    func changeMeasureUnitAction(_ sender: UITapGestureRecognizer) {
        measureUnit = measureUnit.next()
    }
    
    func changeMeasureMode(index: Int) {

        lineSet = nil
        line = nil
        switch mode {
            case .area:
                changeFinishState(state: false)
                placeButton.normalImage  = Image.Place.length
                placeButton.disabledImage = Image.Place.length
                cells[index].imageView.image = UIImage(named: "area")!
                mode = .length
            case .length:
                placeButton.normalImage  = Image.Place.area
                placeButton.disabledImage = Image.Place.area
                cells[index].imageView.image = UIImage(named: "ruler")!
                mode = .area
            }
        resultLabel.attributedText = mode.toAttrStr()
    }
}

// MARK: - UI
fileprivate extension ARCetvelViewController {
    
    func restartSceneView() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        measureUnit = ApplicationSetting.Status.defaultUnit
        resultLabel.attributedText = mode.toAttrStr()
        updateFocusSquare()
    }
    
    func updateLine() -> Void {
        let startPos = sceneView.worldPositionFromScreenPosition(self.indicator.center, objectPos: nil)
        if let p = startPos.position {
            let camera = self.sceneView.session.currentFrame?.camera
            let cameraPos = SCNVector3.positionFromTransform(camera!.transform)
            if cameraPos.distanceFromPos(pos: p) < 0.05 {
                if line == nil {
                    placeButton.isEnabled = false
                    indicator.image = Image.Indicator.disable
                }
                return;
            }
            placeButton.isEnabled = true
            indicator.image = Image.Indicator.enable
            switch mode {
            case .length:
                guard let currentLine = line else {
                    cancleButton.normalImage = Image.Close.delete
                    return
                }
                let length = currentLine.updatePosition(pos: p, camera: self.sceneView.session.currentFrame?.camera, unit: measureUnit)
                measureValue =  MeasurementUnit(meterUnitValue: length, isArea: false)
                cancleButton.normalImage = Image.Close.cancle
            case .area:
                guard let set = lineSet else {
                    changeFinishState(state: false)
                    cancleButton.normalImage = Image.Close.delete
                    return
                }
                let area = set.updatePosition(pos: p, camera: self.sceneView.session.currentFrame?.camera, unit: measureUnit)
                measureValue =  MeasurementUnit(meterUnitValue: area, isArea: true)
                changeFinishState(state: set.lines.count >= 2)
                cancleButton.normalImage = Image.Close.cancle
            }
        }
    }
}

// MARK: - Plane
fileprivate extension ARCetvelViewController {
    func addPlane(node: SCNNode, anchor: ARPlaneAnchor) {
        
        let plane = Plane(anchor, false)
        planes[anchor] = plane
        node.addChildNode(plane)
        indicator.image = Image.Indicator.enable
    }
    
    func updatePlane(anchor: ARPlaneAnchor) {
        if let plane = planes[anchor] {
            plane.update(anchor)
        }
    }
    
    func removePlane(anchor: ARPlaneAnchor) {
        if let plane = planes.removeValue(forKey: anchor) {
            plane.removeFromParentNode()
        }
    }
}

// MARK: - FocusSquare
fileprivate extension ARCetvelViewController {
    
    func setupFocusSquare() {
        focusSquare?.isHidden = true
        focusSquare?.removeFromParentNode()
        focusSquare = FocusSquare()
        sceneView.scene.rootNode.addChildNode(focusSquare!)
    }
    
    func updateFocusSquare() {
        if ApplicationSetting.Status.displayFocus {
            focusSquare?.unhide()
        } else {
            focusSquare?.hide()
        }
        let (worldPos, planeAnchor, _) = sceneView.worldPositionFromScreenPosition(sceneView.bounds.mid, objectPos: focusSquare?.position)
        if let worldPos = worldPos {
            focusSquare?.update(for: worldPos, planeAnchor: planeAnchor, camera: sceneView.session.currentFrame?.camera)
        }
    }
}

// MARK: - ARSCNViewDelegate
extension ARCetvelViewController: ARSCNViewDelegate {
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        DispatchQueue.main.async {
            HUD.show(title: (error as NSError).localizedDescription)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.updateFocusSquare()
            self.updateLine()
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                self.addPlane(node: node, anchor: planeAnchor)
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                self.updatePlane(anchor: planeAnchor)
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                self.removePlane(anchor: planeAnchor)
            }
        }
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        let state = camera.trackingState
        DispatchQueue.main.async {
            self.lastState = state
        }
    }
}
