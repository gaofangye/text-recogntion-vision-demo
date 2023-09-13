//
//  VisionTextInfo.swift
//  text-recogntion-vision-demo
//
//  Created by nannan on 2023/9/13.
//

import SwiftUI

// Vision 解析的文本信息
struct VisionTextInfo: Encodable {
    let uniqueID = UUID().uuidString  // 自动生成唯一 ID
    
    var text: String
    
    var frame: CGRect
}
