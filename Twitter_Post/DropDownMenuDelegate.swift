//
//  DropDownMenuDelegate.swift
//  Twitter_Post
//
//  Created by Gabor Csontos on 12/15/16.
//  Copyright © 2016 GaborMajorszki. All rights reserved.
//


extension PhotoViewController:  DropDownMenuDelegate {
    
    
    private func createMenuCells(_ currentChoice: String) -> [DropDownMenuCell] {
        
        var cells = [DropDownMenuCell]()
        cells.removeAll()
        
        for type in MediaTypes.allValues {
            
            let firstCell = DropDownMenuCell()
            
            firstCell.textLabel!.text = type.rawValue
            firstCell.menuAction = #selector(PhotoViewController.choose(_:))
            firstCell.menuTarget = self
            if currentChoice == type.rawValue {
                firstCell.accessoryType = .checkmark
                
            }
            cells.append(firstCell)
        }
        
        return cells
    }
    
    func prepareNavigationBarMenu(_ currentChoice: String) {
        
        navigationBarMenu = DropDownMenu(frame: (self.view.bounds))
        navigationBarMenu.delegate = self
        
        navigationBarMenu.menuCells = createMenuCells(currentChoice)
        
        // If we set the container to the controller view, the value must be set
        // on the hidden content offset (not the visible one)
        navigationBarMenu.visibleContentOffset =
            navigationController!.navigationBar.frame.size.height// + statusBarHeight()
        
        // For a simple gray overlay in background
        navigationBarMenu.backgroundView = UIView(frame: navigationBarMenu.bounds)
        navigationBarMenu.backgroundView!.backgroundColor = UIColor.black
        navigationBarMenu.backgroundAlpha = 0.7
        
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (context) in
            // If we put this only in -viewDidLayoutSubviews, menu animation is
            // messed up when selecting an item
            self.updateMenuContentOffsets()
        }, completion: nil)
    }
    
    
    
    func updateMenuContentOffsets() {
        navigationBarMenu.visibleContentOffset =
            navigationController!.navigationBar.frame.size.height// + statusBarHeight()
    }
    
    
    func choose(_ sender: AnyObject) {
        
        if let type = (sender as! DropDownMenuCell).textLabel!.text {
            
            dropDownTitle.title = type
            
            
            self.selectedMediaType = MediaTypes(rawValue: type)!
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                
                self.dropDownTitle.toggleMenu()
                
            })
  
        }
    }
    
    
    func willToggleNavigationBarMenu(_ sender: DropdownTitleView) {
        
        
        if sender.isUp {
            
            navigationBarMenu.hide(withAnimation: true)
            
        }
            
        else {
            
            navigationBarMenu.show()
        }
    }
    
    
    func didTapInDropDownMenuBackground(_ menu: DropDownMenu) {
        
        if menu == navigationBarMenu {
            dropDownTitle.toggleMenu()
        }
            
        else {
            
            menu.hide(withAnimation: true)
        }
    }
    
    
    func statusBarHeight() -> CGFloat {
        
        let statusBarSize = UIApplication.shared.statusBarFrame.size
        return min(statusBarSize.width, statusBarSize.height)
        
    }
}
