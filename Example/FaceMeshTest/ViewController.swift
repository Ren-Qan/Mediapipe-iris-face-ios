//
//  ViewController.swift
//  FaceMeshTest
//
//  Created by 任玉乾 on 2022/1/12.
//

import UIKit


class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        let sBtn = UIButton()
        sBtn.setTitle("swift", for: .normal)
        sBtn.addTarget(self, action: #selector(swiftTest), for: .touchUpInside)
        sBtn.frame = CGRect(x: 20, y: 100, width: 50, height: 50)
        sBtn.setTitleColor(.black, for: .normal)
        
        let ocBtn = UIButton()
        ocBtn.setTitle("oc", for: .normal)
        ocBtn.addTarget(self, action: #selector(ocTest), for: .touchUpInside)
        ocBtn.frame = CGRect(x: 100, y: 100, width: 50, height: 50)
        ocBtn.setTitleColor(.black, for: .normal)
        
        let apiExampleBtn = UIButton()
        apiExampleBtn.setTitle("api_example", for: .normal)
        apiExampleBtn.addTarget(self, action: #selector(apiExampleTest), for: .touchUpInside)
        apiExampleBtn.frame = CGRect(x: 180, y: 100, width: 150, height: 50)
        apiExampleBtn.setTitleColor(.black, for: .normal)
        
        view.addSubview(sBtn)
        view.addSubview(ocBtn)
        view.addSubview(apiExampleBtn)
    }

    @objc
    private func swiftTest() {
        let vc = FaceMeshingSwiftViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    
    @objc
    private func ocTest() {
        let vc = FaceMeshingOCViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc
    private func apiExampleTest() {
        let vc = APIViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}

