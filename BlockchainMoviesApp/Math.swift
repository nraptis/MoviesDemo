//
//  Math.swift
//  BlockchainMoviesApp
//
//  Created by Nicky Taylor on 4/9/24.
//

import Foundation
import simd

protocol PointProtocol {
    var x: Float { set get }
    var y: Float { set get }
}

struct IndexPair: Hashable, Equatable {
    let index1: Int
    let index2: Int
}

struct IndexPairOrdered: Hashable, Equatable {
    let index1: Int
    let index2: Int
    init(index1: Int, index2: Int) {
        self.index1 = min(index1, index2)
        self.index2 = max(index1, index2)
    }
}


struct Math {
    
    struct Point: CustomStringConvertible, PointProtocol {
        var x: Float
        var y: Float
        var description: String {
            let stringX = String(format: "%.2f", x)
            let stringY = String(format: "%.2f", y)
            return "Point(\(stringX), \(stringY))"
        }
        
        static func + (left: Point, right: Point) -> Point {
            Point(x: left.x + right.x, y: left.y + right.y)
        }
        
        static func + (left: Point, right: Vector) -> Point {
            Point(x: left.x + right.x, y: left.y + right.y)
        }
        
        static func - (left: Point, right: Point) -> Point {
            Point(x: left.x - right.x, y: left.y - right.y)
        }
        
        static func - (left: Point, right: Vector) -> Point {
            Point(x: left.x - right.x, y: left.y - right.y)
        }
        
        static let zero = Point(x: 0.0, y: 0.0)
        
        var float2: SIMD2<Float> {
            SIMD2<Float>(x, y)
        }
        
        var cgPoint: CGPoint {
            CGPoint(x: CGFloat(x),
                    y: CGFloat(y))
        }
        
        var vector: Vector {
            Vector(x: x,
                   y: y)
        }
        
        func offset(x: Float, y: Float) -> Point {
            Point(x: self.x + x,
                  y: self.y + y)
        }
        
        func distanceSquaredTo(_ point: Point) -> Float {
            distanceSquaredTo(point.x, point.y)
        }
        
        func distanceSquaredTo(_ x: Float, _ y: Float) -> Float {
            let diffX = self.x - x
            let diffY = self.y - y
            return diffX * diffX + diffY * diffY
        }
        
        func distanceTo(_ point: Point) -> Float {
            distanceTo(point.x, point.y)
        }
        
        func distanceTo(_ x: Float, _ y: Float) -> Float {
            var distance = distanceSquaredTo(x, y)
            if distance > Math.epsilon {
                distance = sqrtf(distance)
            }
            return distance
        }
        
        var lengthSquared: Float {
            (x * x) + (y * y)
        }
        
        var length: Float {
            var _result = lengthSquared
            if _result > Math.epsilon {
                _result = sqrtf(_result)
            } else {
                _result = 0.0
            }
            return _result
        }
        
        mutating func normalize() {
            var length = lengthSquared
            if length > Math.epsilon {
                length = sqrtf(length)
                x /= length
                y /= length
            } else {
                print("Attempting to normalize [\(x), \(y)] very near zero...")
                y = -1.0
                x = 0.0
            }
        }
    }
    struct Vector: CustomStringConvertible, PointProtocol {
        var x: Float
        var y: Float
        var description: String {
            let stringX = String(format: "%.2f", x)
            let stringy = String(format: "%.2f", x)
            return "Vector(\(stringX), \(stringy))"
        }
        
        static let zero = Vector(x: 0.0, y: 0.0)
        
        var float2: SIMD2<Float> {
            SIMD2<Float>(x, y)
        }
        
        var cgPoint: CGPoint {
            CGPoint(x: CGFloat(x),
                    y: CGFloat(y))
        }
        
        var point: Point {
            Point(x: x, y: y)
        }
        
        var angle: Float {
            let result = -atan2f(-x, -y)
            return result
        }
        
        var normal: Vector {
            Vector(x: -y, y: x)
        }
        
        var lengthSquared: Float {
            (x * x) + (y * y)
        }
        
        var length: Float {
            var _result = lengthSquared
            if _result > Math.epsilon {
                _result = sqrtf(_result)
            } else {
                _result = 0.0
            }
            return _result
        }
        
        mutating func normalize() {
            var length = lengthSquared
            if length > Math.epsilon {
                length = sqrtf(length)
                x /= length
                y /= length
            } else {
                print("Attempting to normalize [\(x), \(y)] very near zero...")
                y = -1.0
                x = 0.0
            }
        }
        
        static func * (left: Vector, right: Float) -> Vector {
            return Vector(x: left.x * right, y: left.y * right)
        }
        
        static func / (left: Vector, right: Float) -> Vector {
            return Vector(x: left.x / right, y: left.y / right)
        }
        
        static func * (left: Vector, right: Vector) -> Vector {
            return Vector(x: left.x * right.x, y: left.y * right.y)
        }
        
        static func + (left: Vector, right: Vector) -> Vector {
            return Vector(x: left.x + right.x, y: left.y + right.y)
        }
        
        static func - (left: Vector, right: Vector) -> Vector {
            return Vector(x: left.x - right.x, y: left.y - right.y)
        }
        
        static func + (left: Vector, right: Vector) -> Point {
            Point(x: left.x + right.x, y: left.y + right.y)
        }
        
        func dot(_ vector: Vector) -> Float {
            x * vector.x + y * vector.y
        }
        
        func cross(_ vector: Vector) -> Float {
            x * vector.y - vector.x * y
        }
    }
    
    static let pi = Float.pi
    static let pi2 = Float.pi * 2.0
    static let pi3 = Float.pi * 3.0
    static let pi4 = Float.pi * 4.0
    
    static let _pi = -Float.pi
    static let _pi2 = -Float.pi * 2.0
    static let _pi3 = -Float.pi * 3.0
    static let _pi4 = -Float.pi * 4.0
    
    static let pi3_2 = (Float.pi * 3.0) / 2.0
    static let pi2_3 = (Float.pi * 2.0) / 3.0
    static let pi3_4 = (Float.pi * 3.0) / 4.0
    static let pi4_3 = (Float.pi * 4.0) / 3.0
    
    static let pi3_5 = (Float.pi * 3.0) / 5.0
    static let pi5_3 = (Float.pi * 5.0) / 3.0
    static let pi4_5 = (Float.pi * 4.0) / 5.0
    static let pi5_4 = (Float.pi * 5.0) / 4.0
    static let pi5_6 = (Float.pi * 5.0) / 6.0
    static let pi6_5 = (Float.pi * 6.0) / 5.0
    
    
    
    static let _pi3_2 = (-Float.pi * 3.0) / 2.0
    static let _pi2_3 = (-Float.pi * 2.0) / 3.0
    static let _pi3_4 = (-Float.pi * 3.0) / 4.0
    static let _pi4_3 = (-Float.pi * 4.0) / 3.0
    
    static let pi_2 = Float.pi / 2.0
    static let pi_3 = Float.pi / 3.0
    static let pi_4 = Float.pi / 4.0
    static let pi_5 = Float.pi / 5.0
    static let pi_6 = Float.pi / 6.0
    static let pi_7 = Float.pi / 7.0
    static let pi_8 = Float.pi / 8.0
    static let pi_9 = Float.pi / 9.0
    static let pi_10 = Float.pi / 10.0
    static let pi_11 = Float.pi / 11.0
    static let pi_12 = Float.pi / 12.0
    static let pi_13 = Float.pi / 13.0
    static let pi_14 = Float.pi / 14.0
    static let pi_15 = Float.pi / 15.0
    static let pi_16 = Float.pi / 16.0
    static let pi_17 = Float.pi / 17.0
    static let pi_18 = Float.pi / 18.0
    static let pi_19 = Float.pi / 19.0
    static let pi_20 = Float.pi / 20.0
    
    
    static let _pi_2 = -Float.pi / 2.0
    static let _pi_3 = -Float.pi / 3.0
    static let _pi_4 = -Float.pi / 4.0
    static let _pi_5 = -Float.pi / 5.0
    static let _pi_6 = -Float.pi / 6.0
    static let _pi_7 = -Float.pi / 7.0
    static let _pi_8 = -Float.pi / 8.0
    static let _pi_10 = -Float.pi / 10.0
    static let _pi_12 = -Float.pi / 12.0
    static let _pi_14 = -Float.pi / 14.0
    static let _pi_16 = -Float.pi / 16.0
    
    static let epsilon: Float = 0.00001
    //static let epsilon: Float = 0.01
    static let _epsilon = -epsilon
    
    static func radians(degrees: Float) -> Float {
        return degrees * Float.pi / 180.0
    }

    static func degrees(radians: Float) -> Float {
        return radians * 180.0 / Float.pi
    }
    
    static func vector2D(radians: Float) -> Point {
        let x = sinf(radians)
        let y = -cosf(radians)
        return Point(x: x, y: y)
    }

    static func vector2D(degrees: Float) -> Point {
        vector2D(radians: radians(degrees: degrees))
    }
    
    static func distanceBetweenAngles(_ angle1: Float, _ angle2: Float) -> Float {
        var difference = fmodf(angle1 - angle2, Math.pi2)
        if difference < 0 { difference += Math.pi2 }
        if difference > Float.pi {
            return Math.pi2 - difference
        } else {
            return -difference
        }
    }
    
    static func distanceBetweenAnglesUnsafe(_ angle1: Float, _ angle2: Float) -> Float {
        var difference = angle1 - angle2
        if difference < Math._pi2 { difference += Math.pi2 }
        if difference > Math.pi2 { difference -= Math.pi2 }
        if difference < 0 { difference += Math.pi2 }
        if difference > Float.pi {
            return Math.pi2 - difference
        } else {
            return -difference
        }
    }
    
    static func distanceBetweenAnglesAbsolute(_ angle1: Float, _ angle2: Float) -> Float {
        var difference = angle1 - angle2
        if difference > Math.pi4 {
            difference = fmodf(angle1 - angle2, Math.pi2)
        } else if difference < Math._pi4 {
            difference = fmodf(angle1 - angle2, Math.pi2)
        } else if difference > Math.pi2 {
            difference -= Math.pi2
        } else if difference < Math._pi2 {
            difference += Math.pi2
        }
        if difference < 0 { difference += Math.pi2 }
        if difference > Float.pi {
            return Math.pi2 - difference
        } else {
            return difference
        }
    }
    
    static func distanceBetweenAnglesAbsoluteUnsafe(_ angle1: Float, _ angle2: Float) -> Float {
        var difference = angle1 - angle2
        if difference > Math.pi2 {
            difference -= Math.pi2
        } else if difference < Math._pi2 {
            difference += Math.pi2
        }
        if difference < 0.0 {
            difference += Math.pi2
        }
        if difference > Float.pi {
            return Math.pi2 - difference
        } else {
            return difference
        }
    }
    
    static func rotate(float3: simd_float3, radians: Float, axisX: Float, axisY: Float, axisZ: Float) -> simd_float3 {
        var rotationMatrix = matrix_float4x4()
        rotationMatrix.rotation(radians: radians, axisX: axisX, axisY: axisY, axisZ: axisZ)
        return rotationMatrix.processRotationOnly(point3: float3)
    }

    static func rotate(float3: simd_float3, degrees: Float, axisX: Float, axisY: Float, axisZ: Float) -> simd_float3 {
        var rotationMatrix = matrix_float4x4()
        rotationMatrix.rotation(degrees: degrees, axisX: axisX, axisY: axisY, axisZ: axisZ)
        return rotationMatrix.processRotationOnly(point3: float3)
    }

    static func rotateNormalized(float3: simd_float3, radians: Float, axisX: Float, axisY: Float, axisZ: Float) -> simd_float3 {
        var rotationMatrix = matrix_float4x4()
        rotationMatrix.rotationNormalized(radians: radians, axisX: axisX, axisY: axisY, axisZ: axisZ)
        return rotationMatrix.processRotationOnly(point3: float3)
    }

    static func rotateNormalized(float3: simd_float3, degrees: Float, axisX: Float, axisY: Float, axisZ: Float) -> simd_float3 {
        var rotationMatrix = matrix_float4x4()
        rotationMatrix.rotationNormalized(degrees: degrees, axisX: axisX, axisY: axisY, axisZ: axisZ)
        return rotationMatrix.processRotationOnly(point3: float3)
    }
    
    static func rotateX(float3: simd_float3, radians: Float) -> simd_float3 {
        var rotationMatrix = matrix_float4x4()
        rotationMatrix.rotationX(radians: radians)
        return rotationMatrix.processRotationOnly(point3: float3)
    }

    static func rotateX(float3: simd_float3, degrees: Float) -> simd_float3 {
        var rotationMatrix = matrix_float4x4()
        rotationMatrix.rotationX(degrees: degrees)
        return rotationMatrix.processRotationOnly(point3: float3)
    }
    
    static func rotateY(float3: simd_float3, radians: Float) -> simd_float3 {
        var rotationMatrix = matrix_float4x4()
        rotationMatrix.rotationY(radians: radians)
        return rotationMatrix.processRotationOnly(point3: float3)
    }

    static func rotateY(float3: simd_float3, degrees: Float) -> simd_float3 {
        var rotationMatrix = matrix_float4x4()
        rotationMatrix.rotationY(degrees: degrees)
        return rotationMatrix.processRotationOnly(point3: float3)
    }
    
    static func rotateZ(float3: simd_float3, radians: Float) -> simd_float3 {
        var rotationMatrix = matrix_float4x4()
        rotationMatrix.rotationZ(radians: radians)
        return rotationMatrix.processRotationOnly(point3: float3)
    }

    static func rotateZ(float3: simd_float3, degrees: Float) -> simd_float3 {
        var rotationMatrix = matrix_float4x4()
        rotationMatrix.rotationZ(degrees: degrees)
        return rotationMatrix.processRotationOnly(point3: float3)
    }
    
    
    static func quadBoundingBoxContainsPoint2D(x: Float, y: Float,
                                        quadX1: Float, quadY1: Float,
                                        quadX2: Float, quadY2: Float,
                                        quadX3: Float, quadY3: Float,
                                        quadX4: Float, quadY4: Float) -> Bool {
        
        var minX = min(quadX1, min(quadX2, min(quadX3, quadX4)))
        var minY = min(quadY1, min(quadY2, min(quadY3, quadY4)))
        var maxX = max(quadX1, max(quadX2, max(quadX3, quadX4)))
        var maxY = max(quadY1, max(quadY2, max(quadY3, quadY4)))
        
        minX -= Self.epsilon
        minY -= Self.epsilon
        maxX += Self.epsilon
        maxY += Self.epsilon
        
        return (x >= minX) && (x <= maxX) && (y >= minY) && (y <= maxY)
    }
    
    private static var quadListX = [Float](repeating: 0.0, count: 4)
    private static var quadListY = [Float](repeating: 0.0, count: 4)
    static func quadContainsPoint2D(x: Float, y: Float,
                                    quadX1: Float, quadY1: Float,
                                    quadX2: Float, quadY2: Float,
                                    quadX3: Float, quadY3: Float,
                                    quadX4: Float, quadY4: Float) -> Bool {
        
        quadListX[0] = quadX1
        quadListX[1] = quadX2
        quadListX[2] = quadX3
        quadListX[3] = quadX4
        
        quadListY[0] = quadY1
        quadListY[1] = quadY2
        quadListY[2] = quadY3
        quadListY[3] = quadY4
        
        var end = 3
        var start = 0
        var result = false
        while start < 4 {
            if (((quadListY[start] <= y ) && (y < quadListY[end]))
                || ((quadListY[end] <= y) && (y < quadListY[start])))
                && (x < (quadListX[end] - quadListX[start]) * (y - quadListY[start])
                    / (quadListY[end] - quadListY[start]) + quadListX[start]) {
                result = !result
            }
            end = start
            start += 1
        }
        return result
    }
    
    static func distance(point1: Point, point2: Point) -> Float {
        let diffX = point2.x - point1.x
        let diffY = point2.y - point1.y
        let distanceSquared = diffX * diffX + diffY * diffY
        if distanceSquared > Self.epsilon {
            return sqrtf(distanceSquared)
        } else {
            return 0.0
        }
    }
    
    static func distance(x1: Float, y1: Float, x2: Float, y2: Float) -> Float {
        let diffX = x2 - x1
        let diffY = y2 - y1
        let distanceSquared = diffX * diffX + diffY * diffY
        if distanceSquared > Self.epsilon {
            return sqrtf(distanceSquared)
        } else {
            return 0.0
        }
    }

    static func distanceSquared(point1: Point, point2: Point) -> Float {
        let diffX = point2.x - point1.x
        let diffY = point2.y - point1.y
        return diffX * diffX + diffY * diffY
    }
    
    static func distanceSquared(x1: Float, y1: Float, x2: Float, y2: Float) -> Float {
        let diffX = x2 - x1
        let diffY = y2 - y1
        return diffX * diffX + diffY * diffY
    }
    
    static func rangesContainsValue(start: Float, end: Float, value: Float) -> Bool {
        if value >= start && value <= end {
            return true
        }
        if value >= end && value <= start {
            return true
        }
        return false
    }
    
    static func rangesOverlap(start1: Float, end1: Float, start2: Float, end2: Float) -> Bool {
        if start1 < end1 {
            if start2 >= start1 && start2 <= end1 {
                return true
            }
            if end2 >= start1 && end2 <= end1 {
                return true
            }
            if start2 < end2 {
                if start1 >= start2 && start1 <= end2 {
                    return true
                }
                if end1 >= start2 && end1 <= end2 {
                    return true
                }
            } else {
                if start1 >= end2 && start1 <= start2 {
                    return true
                }
                if end1 >= end2 && end1 <= start2 {
                    return true
                }
            }
        } else {
            if start2 >= end1 && start2 <= start1 {
                return true
            }
            if end2 >= end1 && end2 <= start1 {
                return true
            }
            if start2 < end2 {
                if end1 >= start2 && end1 <= end2 {
                    return true
                }
                if start1 >= start2 && start1 <= end2 {
                    return true
                }
            } else {
                if end1 >= end2 && end1 <= start2 {
                    return true
                }
                if start1 >= end2 && start1 <= start2 {
                    return true
                }
            }
        }
        return false
    }
    
    static func perpendicularNormal(float3: simd_float3) -> simd_float3 {
        
        let factorX = fabsf(float3.x)
        let factorY = fabsf(float3.y)
        let factorZ = fabsf(float3.z)

        var result = simd_float3(0.0, 0.0, 0.0)
        if factorX < Math.epsilon {
            if factorY < Math.epsilon {
                result.y = 1.0
            } else {
                result.y = -float3.z
                result.z = float3.y
            }
        } else if factorY < Math.epsilon {
            if factorZ < Math.epsilon {
                result.y = -1
            } else {
                result.x = -float3.z
                result.z = float3.x
            }
        } else if factorZ < Math.epsilon {
            result.x = -float3.y
            result.y = float3.x
        } else {
            result.x = 1.0
            result.y = 1.0
            result.z = -((float3.x + float3.y) / float3.z)
        }
        
        return simd_normalize(result)
    }
    
    static func equalsApproximately(number1: Float, number2: Float) -> Bool {
        let diff = abs(number1 - number2)
        return diff <= epsilon
    }
    
    static func clamp(number: Float, lower: Float, upper: Float) -> Float {
        var result = number
        if result < lower { result = lower }
        if result > upper { result = upper }
        return result
    }
    
    static func angleDistance(radians1: Float, radians2: Float) -> Float {
        var distance = radians1 - radians2
        distance = fmodf(distance, (Float.pi * 2.0))
        if distance < 0.0 { distance += (Float.pi * 2.0) }
        if distance > Float.pi {
            return (Float.pi * 2.0) - distance
        } else {
            return -distance
        }
    }
    
    static func angleDistance(degrees1: Float, degrees2: Float) -> Float {
        let radians1 = radians(degrees: degrees1)
        let radians2 = radians(degrees: degrees2)
        return angleDistance(radians1: radians1, radians2: radians2)
    }
    
    static func fallOffOvershoot(input: Float, falloffStart: Float, resultMax: Float, inputMax: Float) -> Float {
        var result = input
        if result > falloffStart {
            result = resultMax
            if input < inputMax {
                //We are constrained between [falloffStart ... inputMax]
                let span = (inputMax - falloffStart)
                if span > Math.epsilon {
                    var percent = (input - falloffStart) / span
                    if percent < 0.0 { percent = 0.0 }
                    if percent > 1.0 { percent = 1.0 }
                    //sin [0..1] => [0..pi/2]
                    let factor = sinf(Float(percent * (Float.pi * 0.5)))
                    result = falloffStart + factor * (resultMax - falloffStart)
                }
            }
        }
        return result
    }
    
    static func fallOffUndershoot(input: Float, falloffStart: Float, resultMin: Float, inputMin: Float) -> Float {
        var result = input
        if result < falloffStart {
            result = resultMin
            if input > inputMin {
                //We are constrained between [inputMin ... falloffStart]
                let span = (falloffStart - inputMin)
                if span > Math.epsilon {
                    var percent = (falloffStart - input) / span
                    if percent < 0.0 { percent = 0.0 }
                    if percent > 1.0 { percent = 1.0 }
                    //sin [0..1] => [0..pi/2]
                    let factor = sinf(Float(percent * (Float.pi * 0.5)))
                    result = falloffStart - factor * (falloffStart - resultMin)
                }
            }
        }
        return result
    }
    
    public static func angleToVector(radians: Float) -> Point {
        .init(x: sinf(radians), y: -cosf(radians))
    }
    
    public static func face(target: Point) -> Float {
        -atan2f(Float(-target.x), Float(-target.y))
    }
    
    public static func rotatePoint(point: Point, radians: Float) -> Point {
        var dist = point.x * point.x + point.y * point.y
        if dist > epsilon {
            dist = sqrtf(dist)
            let pivot = face(target: point)
            let newDir = angleToVector(radians: pivot + radians)
            return Point(x: newDir.x * dist, y: newDir.y * dist)
        }
        return point
    }
    
    public static func transformPoint(point: Point, scale: Float, rotation: Float) -> Point {
        var x = point.x
        var y = point.y
        if scale != 1.0 {
            x *= scale
            y *= scale
        }
        if rotation != 0 {
            var dist = x * x + y * y
            if dist > epsilon {
                dist = sqrtf(Float(dist))
                x /= dist
                y /= dist
            }
            let pivotRotation = rotation - atan2f(-x, -y)
            x = sinf(Float(pivotRotation)) * dist
            y = -cosf(Float(pivotRotation)) * dist
        }
        return Point(x: x, y: y)
    }
    
    public static func transformPoint(point: Point, translation: Point, scale: Float, rotation: Float) -> Point {
        var result = transformPoint(point: point, scale: scale, rotation: rotation)
        result = Point(x: result.x + translation.x, y: result.y + translation.y)
        return result
    }
    
    public static func untransformPoint(point: Point, scale: Float, rotation: Float) -> Point {
        transformPoint(point: point, scale: 1.0 / scale, rotation: -rotation)
    }
    
    public static func untransformPoint(point: Point, translation: Point, scale: Float, rotation: Float) -> Point {
        var result = Point(x: point.x - translation.x, y: point.y - translation.y)
        result = untransformPoint(point: result, scale: scale, rotation: rotation)
        return result
    }
    
    static func clockwise(point1: Point, point2: Point, point3: Point) -> Bool {
        (point2.x - point1.x) * (point3.y - point2.y) - (point3.x - point2.x) * (point2.y - point1.y) > 0.0
    }
    
    /*
    enum LineSegmentNormalResult {
        case invalid
        case valid(normal: Vector)
    }
    
    static func lineSegmentNormal(linePoint1: Point, linePoint2: Point) -> LineSegmentNormalResult {
        var direction = Vector(x: linePoint2.x - linePoint1.x,
                               y: linePoint2.y - linePoint1.y)
        var length = direction.lengthSquared
        if length > Math.epsilon {
            length = sqrtf(length)
            directionX /= length
            directionY /= length
            let normal = direction.normal
            return LineSegmentNormalResult.valid(normal: normal)
        } else {
            return LineSegmentNormalResult.invalid
        }
    }
    
    enum LineRayIntersectionResult {
        case invalidLineNormal
        case invalidCoplanar
        case valid(pointX: Float, pointY: Float, distance: Float)
    }
    // Precondition: rayDirection is normalized
    static func lineIntersectionRay(linePoint1: Point, linePoint2: Point,
                                    rayOrigin: Point, rayDirection: Vector) -> LineRayIntersectionResult {
        let lineNormalResult = lineSegmentNormal(linePoint1: linePoint1,
                                                 linePoint2: linePoint2)
        switch lineNormalResult {
        case .invalid:
            return .invalidLineNormal
        case .valid(let lineNormal):
            let rayIntersectionRayResult = rayIntersectionRay(rayOrigin1: linePoint1, rayNormal1: lineNormal,
                                                              rayOrigin2: rayOrigin, rayDirection2: rayDirection)
            switch rayIntersectionRayResult {
            case .invalidCoplanar:
                return .invalidCoplanar
            case .valid(let pointX, let pointY, let distance):
                return .valid(pointX: pointX, pointY: pointY, distance: distance)
            }
        }
    }
    */
    
    enum RayRayIntersectionResult {
        case invalidCoplanar
        case valid(pointX: Float, pointY: Float, distance: Float)
    }
    // Precondition: rayNormal1 is normalized
    // Precondition: rayDirection2 is normalized
    static func rayIntersectionRay(rayOrigin1X: Float,
                                   rayOrigin1Y: Float,
                                   rayNormal1X: Float,
                                   rayNormal1Y: Float,
                                   rayOrigin2X: Float,
                                   rayOrigin2Y: Float,
                                   rayDirection2X: Float,
                                   rayDirection2Y: Float) -> RayRayIntersectionResult {
            let numerator = rayNormal1X * rayOrigin2X +
                            rayNormal1Y * rayOrigin2Y -
                            dot(x1: rayOrigin1X, y1: rayOrigin1Y,
                                x2: rayNormal1X, y2: rayNormal1Y)
            let denominator = rayDirection2X * rayNormal1X + rayDirection2Y * rayNormal1Y
            if denominator < _epsilon || denominator > epsilon {
                let distance = -(numerator / denominator)
                return .valid(pointX: rayOrigin2X + rayDirection2X * distance,
                              pointY: rayOrigin2Y + rayDirection2Y * distance,
                              distance: distance)
            } else {
                return .invalidCoplanar
            }
        }
    
    static func segmentClosestPoint(point: Point,
                                    linePoint1: Point,
                                    linePoint2: Point) -> Point {
        var result = Point(x: linePoint1.x, y: linePoint1.y)
        let factor1X = point.x - linePoint1.x
        let factor1Y = point.y - linePoint1.y
        let lineDiffX = linePoint2.x - linePoint1.x
        let lineDiffY = linePoint2.y - linePoint1.y
        var factor2X = lineDiffX
        var factor2Y = lineDiffY
        var lineLength = lineDiffX * lineDiffX + lineDiffY * lineDiffY
        if lineLength > Math.epsilon {
            lineLength = sqrtf(lineLength)
            factor2X /= lineLength
            factor2Y /= lineLength
            let scalar = factor2X * factor1X + factor2Y * factor1Y
            if scalar < 0.0 {
                result.x = linePoint1.x
                result.y = linePoint1.y
            } else if scalar > lineLength {
                result.x = linePoint2.x
                result.y = linePoint2.y
            } else {
                result.x = linePoint1.x + factor2X * scalar
                result.y = linePoint1.y + factor2Y * scalar
            }
        }
        return result
    }

    static func segmentClosestPointIsOnSegment(point: Point,
                                               linePoint1: Point,
                                               linePoint2: Point) -> Bool {
        let factor1X = point.x - linePoint1.x
        let factor1Y = point.y - linePoint1.y
        let lineDiffX = linePoint2.x - linePoint1.x
        let lineDiffY = linePoint2.y - linePoint1.y
        var factor2X = lineDiffX
        var factor2Y = lineDiffY
        var lineLength = lineDiffX * lineDiffX + lineDiffY * lineDiffY
        if lineLength > Math.epsilon {
            lineLength = sqrtf(lineLength)
            factor2X /= lineLength
            factor2Y /= lineLength
            let scalar = factor2X * factor1X + factor2Y * factor1Y
            if scalar < 0.0 || scalar > 1.0 {
                return false
            } else {
                return true
            }
        }
        return false
    }
    
    static func pointEmbeddedInLineSegmentPlane(point: Point, linePoint1: Point, linePoint2: Point) -> Bool {
        cross(x1: linePoint2.x - linePoint1.x,
              y1: linePoint2.y - linePoint1.y,
              x2: point.x - linePoint1.x,
              y2: point.y - linePoint1.y) < 0.0
    }
    
    static func pointEmbeddedInPlane(point: Point, planeOrigin: Point, planeDirection: Vector) -> Bool {
        cross(x1: planeDirection.x,
              y1: planeDirection.y,
              x2: point.x - planeOrigin.x,
              y2: point.y - planeOrigin.y) < 0.0
    }
    
    static func pointEmbeddedInPlaneFlipped(point: Point, planeOrigin: Point, planeDirection: Vector) -> Bool {
        cross(x1: -planeDirection.x,
              y1: -planeDirection.y,
              x2: point.x - planeOrigin.x,
              y2: point.y - planeOrigin.y) < 0.0
    }
    
    
    static func lineSegmentFacesLineSegment(line1Point1: Point, line1Point2: Point, line2Point1: Point, line2Point2: Point) -> Bool {
        // If both of line 1 are embedded in line 2, then no.
        if
            pointEmbeddedInLineSegmentPlane(point: line1Point1,
                                           linePoint1: line2Point1,
                                           linePoint2: line2Point2)  &&
            pointEmbeddedInLineSegmentPlane(point: line1Point2,
                                               linePoint1: line2Point1,
                                               linePoint2: line2Point2){
            return false
        }
        
        // If both of line 2 are embedded in line 1, then no.
        if
            pointEmbeddedInLineSegmentPlane(point: line2Point1,
                                           linePoint1: line1Point1,
                                           linePoint2: line1Point2)  &&
            pointEmbeddedInLineSegmentPlane(point: line2Point2,
                                               linePoint1: line1Point1,
                                               linePoint2: line1Point2){
            return false
        }
        return true
    }
    
    struct TriangleAnglesResult {
        let angle1: Float
        let angle2: Float
        let angle3: Float
    }
    static func triangleAngles(point1: Point, point2: Point, point3: Point) -> TriangleAnglesResult {
        
        let lineDirX1 = point1.x - point2.x
        let lineDirY1 = point1.y - point2.y
        guard (lineDirX1 * lineDirX1 + lineDirY1 * lineDirY1) > Math.epsilon else {
            return TriangleAnglesResult(angle1: Math.pi, angle2: 0.0, angle3: 0.0)
        }
        
        let lineDirX2 = point2.x - point3.x
        let lineDirY2 = point2.y - point3.y
        guard (lineDirX2 * lineDirX2 + lineDirY2 * lineDirY2) > Math.epsilon else {
            return TriangleAnglesResult(angle1: 0.0, angle2: Math.pi, angle3: 0.0)
        }
        
        let lineDirX3 = point3.x - point1.x
        let lineDirY3 = point3.y - point1.y
        guard (lineDirX3 * lineDirX3 + lineDirY3 * lineDirY3) > Math.epsilon else {
            return TriangleAnglesResult(angle1: 0.0, angle2: 0.0, angle3: Math.pi)
        }
        
        let lineDirAngle1 = atan2f(lineDirX1, lineDirY1)
        let lineDirAngle2 = atan2f(lineDirX2, lineDirY2)
        let lineDirAngle3 = atan2f(lineDirX3, lineDirY3)
        
        let antiAngle1 = distanceBetweenAnglesAbsoluteUnsafe(lineDirAngle3, lineDirAngle1)
        let antiAngle2 = distanceBetweenAnglesAbsoluteUnsafe(lineDirAngle2, lineDirAngle1)
        let antiAngle3 = distanceBetweenAnglesAbsoluteUnsafe(lineDirAngle2, lineDirAngle3)
        
        return TriangleAnglesResult(angle1: Math.pi - antiAngle1,
                                    angle2: Math.pi - antiAngle2,
                                    angle3: Math.pi - antiAngle3)
    }
    
    static func triangleMinimumAngle(point1: Point, point2: Point, point3: Point) -> Float {
        
        let lineDirX1 = point1.x - point2.x
        let lineDirY1 = point1.y - point2.y
        guard (lineDirX1 * lineDirX1 + lineDirY1 * lineDirY1) > Math.epsilon else {
            return 0.0
        }
        
        let lineDirX2 = point2.x - point3.x
        let lineDirY2 = point2.y - point3.y
        guard (lineDirX2 * lineDirX2 + lineDirY2 * lineDirY2) > Math.epsilon else {
            return 0.0
        }
        
        let lineDirX3 = point3.x - point1.x
        let lineDirY3 = point3.y - point1.y
        guard (lineDirX3 * lineDirX3 + lineDirY3 * lineDirY3) > Math.epsilon else {
            return 0.0
        }
        
        let lineDirAngle1 = atan2f(lineDirX1, lineDirY1)
        let lineDirAngle2 = atan2f(lineDirX2, lineDirY2)
        let lineDirAngle3 = atan2f(lineDirX3, lineDirY3)
        
        let antiAngle1 = distanceBetweenAnglesAbsoluteUnsafe(lineDirAngle3, lineDirAngle1)
        let antiAngle2 = distanceBetweenAnglesAbsoluteUnsafe(lineDirAngle2, lineDirAngle1)
        let antiAngle3 = distanceBetweenAnglesAbsoluteUnsafe(lineDirAngle2, lineDirAngle3)
        
        let triangleAngle1 = Math.pi - antiAngle1
        let triangleAngle2 = Math.pi - antiAngle2
        let triangleAngle3 = Math.pi - antiAngle3
        
        var result = triangleAngle1
        if triangleAngle2 < result { result = triangleAngle2 }
        if triangleAngle3 < result { result = triangleAngle3 }
        
        return result
    }
    
    //
    // This is specifically the angle with p2 as the center point
    //
    //  P1
    //  |
    //  |
    //  P2-----P3
    //
    //  would return pi / 2
    //
    static func triangleAngle(x1: Float, y1: Float, x2: Float, y2: Float, x3: Float, y3: Float) -> Float {
        
        // the angle of line (p1, p2)
        let angle1 = -atan2f(-(x1 - x2), -(y1 - y2))
        
        // the angle of line (p3, p2)
        let angle2 = -atan2f(-(x3 - x2), -(y3 - y2))

        // add the 2 directions together, this is the "p2 normal"
        let normalX = sin(angle1) + sin(angle2)
        let normalY = -cos(angle1) - cos(angle2)
        
        // maybe we are exceedingly close to 180 degrees, e.g. the normal is tiny
        guard (normalX * normalX + normalY * normalY > Math.epsilon) else {
            
            // make small adjustment to the angles, this will still
            // be the exact same answer (within floating point percision).
            let normalX = sin(angle1 - 0.25) + sin(angle2 + 0.25)
            let normalY = -cos(angle1 - 0.25) - cos(angle2 + 0.25)
            
            // angle of the point's normal
            let angle3 = -atan2f(-normalX, -normalY)
            
            // the point normal bend to one of the line segments
            var difference = angle3 - angle1
            
            if difference < 0.0 {
                // all our angles are positive
                difference += Math.pi2
            }
            
            // the opposite part of the circle, which is half of
            // the full "point 2 angle"
            let half = Math.pi2 - difference
            
            // half + half = whole
            return half + half
        }
        
        // angle of the point's normal
        let angle3 = -atan2f(-normalX, -normalY)
        
        // the point normal bend to one of the line segments
        var difference = angle3 - angle1
        if difference < 0.0 {
            // all our angles are positive
            difference += Math.pi2
        }
        
        //
        // if the triangle is clockwise, we are less than 180 degrees,
        // otherwise, we are more than 180 degrees, so the math is different.
        //
        if (x1 * y2 + x3 * y1 + x2 * y3 - x1 * y3 - x3 * y2 - x2 * y1) > 0.0 {
            // the opposite part of the circle, which is half of
            // the full "point 2 angle"
            let half = Math.pi2 - difference
            
            // half + half = whole
            return half + half
        } else {
            
            // the opposite part of the circle, which is half of
            // the full "point 2 angle", so we take twice
            return Math.pi2 - (difference + difference)
        }
    }
    
    /*
    static func triangleAngle(x1: Float, y1: Float, x2: Float, y2: Float, x3: Float, y3: Float) -> Float {
        
        let angle1 = -atan2f(-(x1 - x2), -(y1 - y2))
        let angle2 = -atan2f(-(x3 - x2), -(y3 - y2))
        
        let dirX1 = sin(angle1)
        let dirY1 = -cos(angle1)
        
        let dirX2 = sin(angle2)
        let dirY2 = -cos(angle2)
        
        var normalX = dirX1 + dirX2
        var normalY = dirY1 + dirY2
        
        guard (normalX * normalX + normalY * normalY > 0.2) else {
            
            let dirX1 = sin(angle1 - 0.25)
            let dirY1 = -cos(angle1 - 0.25)
            
            let dirX2 = sin(angle2 + 0.25)
            let dirY2 = -cos(angle2 + 0.25)
            
            var normalX = dirX1 + dirX2
            var normalY = dirY1 + dirY2
            
            let angle3 = -atan2f(-normalX, -normalY)
            
            var difference = angle3 - angle1
            if difference < 0.0 {
                difference += Math.pi2
            }
            
            let half = Math.pi2 - difference
            return half + half

        }
        
        let angle3 = -atan2f(-normalX, -normalY)
        
        var difference = angle3 - angle1
        if difference < 0.0 {
            difference += Math.pi2
        }
        
        if (x1 * y2 + x3 * y1 + x2 * y3 - x1 * y3 - x3 * y2 - x2 * y1) > 0.0 {
            let half = Math.pi2 - difference
            return half + half
        } else {
            return Math.pi2 - (difference + difference)
        }
    }
    */
    
    static func triangleMinimumAngle(x1: Float, y1: Float, x2: Float, y2: Float, x3: Float, y3: Float) -> Float {
        
        let lineDirX1 = x1 - x2
        let lineDirY1 = y1 - y2
        guard (lineDirX1 * lineDirX1 + lineDirY1 * lineDirY1) > Math.epsilon else {
            return 0.0
        }
        
        let lineDirX2 = x2 - x3
        let lineDirY2 = y2 - y3
        guard (lineDirX2 * lineDirX2 + lineDirY2 * lineDirY2) > Math.epsilon else {
            return 0.0
        }
        
        let lineDirX3 = x3 - x1
        let lineDirY3 = y3 - y1
        guard (lineDirX3 * lineDirX3 + lineDirY3 * lineDirY3) > Math.epsilon else {
            return 0.0
        }
        
        let lineDirAngle1 = atan2f(lineDirX1, lineDirY1)
        let lineDirAngle2 = atan2f(lineDirX2, lineDirY2)
        let lineDirAngle3 = atan2f(lineDirX3, lineDirY3)
        
        let triangleAngle1 = Math.pi - distanceBetweenAnglesAbsoluteUnsafe(lineDirAngle3, lineDirAngle1)
        let triangleAngle2 = Math.pi - distanceBetweenAnglesAbsoluteUnsafe(lineDirAngle2, lineDirAngle1)
        let triangleAngle3 = Math.pi - distanceBetweenAnglesAbsoluteUnsafe(lineDirAngle2, lineDirAngle3)
        
        var result = triangleAngle1
        if triangleAngle2 < result { result = triangleAngle2 }
        if triangleAngle3 < result { result = triangleAngle3 }
        
        return result
    }
    
    static func triangleArea(point1: Point, point2: Point, point3: Point) -> Float {
        (point2.x - point1.x) * (point3.y - point1.y) - (point3.x - point1.x) * (point2.y - point1.y)
    }
    
    static func triangleArea(x1: Float, y1: Float, x2: Float, y2: Float, x3: Float, y3: Float) -> Float {
        (x2 - x1) * (y3 - y1) - (x3 - x1) * (y2 - y1)
    }
    
    static func triangleAreaAbsolute(point1: Point, point2: Point, point3: Point) -> Float {
        let area = (point2.x - point1.x) * (point3.y - point1.y) - (point3.x - point1.x) * (point2.y - point1.y)
        if area < 0.0 {
            return -area
        } else {
            return area
        }
    }
    
    static func triangleAreaAbsolute(x1: Float, y1: Float, x2: Float, y2: Float, x3: Float, y3: Float) -> Float {
        let area = (x2 - x1) * (y3 - y1) - (x3 - x1) * (y2 - y1)
        if area < 0.0 {
            return -area
        } else {
            return area
        }
    }
    
    private static func between(x1: Float, y1: Float, x2: Float, y2: Float, x3: Float, y3: Float) -> Bool {
        if fabsf(x1 - x2) > Math.epsilon {
            return (((x1 <= x3) && (x3 <= x2)) || ((x1 >= x3) && (x3 >= x2)))
        } else {
            return ((y1 <= y3) && (y3 <= y2)) || ((y1 >= y3) && (y3 >= y2))
        }
    }
    
    /*
    static func lineSegmentIntersectsLineSegment(line1Point1X: Float,
                                                 line1Point1Y: Float,
                                                 line1Point2X: Float,
                                                 line1Point2Y: Float,
                                                 line2Point1X: Float,
                                                 line2Point1Y: Float,
                                                 line2Point2X: Float,
                                                 line2Point2Y: Float) -> Bool {

        let result1 = lineSegmentIntersectsLineSegmentOld(line1Point1X: line1Point1X,
                                                          line1Point1Y: line1Point1Y,
                                                          line1Point2X: line1Point2X,
                                                          line1Point2Y: line1Point2Y,
                                                          line2Point1X: line2Point1X,
                                                          line2Point1Y: line2Point1Y,
                                                          line2Point2X: line2Point2X,
                                                          line2Point2Y: line2Point2Y)
        
        let result2 = lineSegmentIntersectsLineSegmentNew(line1Point1X: line1Point1X,
                                                          line1Point1Y: line1Point1Y,
                                                          line1Point2X: line1Point2X,
                                                          line1Point2Y: line1Point2Y,
                                                          line2Point1X: line2Point1X,
                                                          line2Point1Y: line2Point1Y,
                                                          line2Point2X: line2Point2X,
                                                          line2Point2Y: line2Point2Y)
        
        if result1 != result2 {
            print("Mismatch Line Segments [\(line1Point1X) \(line1Point1Y), \(line1Point2X) \(line1Point2Y)], [\(line2Point1X) \(line2Point1Y), \(line2Point2X) \(line2Point2Y)]")
            fatalError("You Are Gay!")
        }
        
        return result2
    }
    */
    
    static func lineSegmentIntersectsLineSegment(line1Point1X: Float,
                                                 line1Point1Y: Float,
                                                 line1Point2X: Float,
                                                 line1Point2Y: Float,
                                                 line2Point1X: Float,
                                                 line2Point1Y: Float,
                                                 line2Point2X: Float,
                                                 line2Point2Y: Float) -> Bool {
        
        let area1 = (line1Point2X - line1Point1X) * (line2Point1Y - line1Point1Y) - (line2Point1X - line1Point1X) * (line1Point2Y - line1Point1Y)
        if fabsf(area1) < Math.epsilon {
            if fabsf(line1Point1X - line1Point2X) > Math.epsilon {
                if (line1Point1X <= line2Point1X) && (line2Point1X <= line1Point2X) {
                    return true
                } else if (line1Point1X >= line2Point1X) && (line2Point1X >= line1Point2X) {
                    return true
                }
            } else {
                if (line1Point1Y <= line2Point1Y) && (line2Point1Y <= line1Point2Y) {
                    return true
                } else if (line1Point1Y >= line2Point1Y) && (line2Point1Y >= line1Point2Y) {
                    return true
                }
            }
            if fabsf((line1Point2X - line1Point1X) * (line2Point2Y - line1Point1Y) -
                     (line2Point2X - line1Point1X) * (line1Point2Y - line1Point1Y)) < Math.epsilon {
                if fabsf(line2Point1X - line2Point2X) > Math.epsilon {
                    if (line2Point1X <= line1Point1X) && (line1Point1X <= line2Point2X) {
                        return true
                    } else if (line2Point1X >= line1Point1X) && (line1Point1X >= line2Point2X) {
                        return true
                    } else if (line2Point1X <= line1Point2X) && (line1Point2X <= line2Point2X) {
                        return true
                    } else if (line2Point1X >= line1Point2X) && (line1Point2X >= line2Point2X) {
                        return true
                    }
                } else {
                    if (line2Point1Y <= line1Point1Y) && (line1Point1Y <= line2Point2Y) {
                        return true
                    } else if (line2Point1Y >= line1Point1Y) && (line1Point1Y >= line2Point2Y) {
                        return true
                    } else if (line2Point1Y <= line1Point2Y) && (line1Point2Y <= line2Point2Y) {
                        return true
                    } else if (line2Point1Y >= line1Point2Y) && (line1Point2Y >= line2Point2Y) {
                        return true
                    }
                }
            }
            return false
        }
        
        let area2 = (line1Point2X - line1Point1X) * (line2Point2Y - line1Point1Y) - (line2Point2X - line1Point1X) * (line1Point2Y - line1Point1Y)
        if fabsf(area2) < Math.epsilon {
            if fabsf(line1Point1X - line1Point2X) > Math.epsilon {
                if (line1Point1X <= line2Point2X) && (line2Point2X <= line1Point2X) {
                    return true
                } else if (line1Point1X >= line2Point2X) && (line2Point2X >= line1Point2X) {
                    return true
                } else {
                    return false
                }
            } else {
                if (line1Point1Y <= line2Point2Y) && (line2Point2Y <= line1Point2Y) {
                    return true
                } else if (line1Point1Y >= line2Point2Y) && (line2Point2Y >= line1Point2Y) {
                    return true
                } else {
                    return false
                }
            }
        }
        
        let area3 = (line2Point2X - line2Point1X) * (line1Point1Y - line2Point1Y) - (line1Point1X - line2Point1X) * (line2Point2Y - line2Point1Y)
        if fabsf(area3) < Math.epsilon {
            
            if fabsf(line2Point1X - line2Point2X) > Math.epsilon {
                if (line2Point1X <= line1Point1X) && (line1Point1X <= line2Point2X) {
                    return true
                } else if (line2Point1X >= line1Point1X) && (line1Point1X >= line2Point2X) {
                    return true
                }
            } else {
                if (line2Point1Y <= line1Point1Y) && (line1Point1Y <= line2Point2Y) {
                    return true
                } else if (line2Point1Y >= line1Point1Y) && (line1Point1Y >= line2Point2Y) {
                    return true
                }
            }
            if fabsf((line2Point2X - line2Point1X) * (line1Point2Y - line2Point1Y) -
                     (line1Point2X - line2Point1X) * (line2Point2Y - line2Point1Y)) < Math.epsilon {
                if fabsf(line1Point1X - line1Point2X) > Math.epsilon {
                    if (line1Point1X <= line2Point1X) && (line2Point1X <= line1Point2X) {
                        return true
                    } else if (line1Point1X >= line2Point1X) && (line2Point1X >= line1Point2X) {
                        return true
                    } else if (line1Point1X <= line2Point2X) && (line2Point2X <= line1Point2X) {
                        return true
                    } else if (line1Point1X >= line2Point2X) && (line2Point2X >= line1Point2X) {
                        return true
                    }
                } else {
                    if (line1Point1Y <= line2Point1Y) && (line2Point1Y <= line1Point2Y) {
                        return true
                    } else if (line1Point1Y >= line2Point1Y) && (line2Point1Y >= line1Point2Y) {
                        return true
                    } else if (line1Point1Y <= line2Point2Y) && (line2Point2Y <= line1Point2Y) {
                        return true
                    } else if (line1Point1Y >= line2Point2Y) && (line2Point2Y >= line1Point2Y) {
                        return true
                    }
                }
            }
            return false
        }
        let area4 = (line2Point2X - line2Point1X) * (line1Point2Y - line2Point1Y) - (line1Point2X - line2Point1X) * (line2Point2Y - line2Point1Y)
        if fabsf(area4) < Math.epsilon {
            if fabsf(line2Point1X - line2Point2X) > Math.epsilon {
                if (line2Point1X <= line1Point2X) && (line1Point2X <= line2Point2X) {
                    return true
                } else if (line2Point1X >= line1Point2X) && (line1Point2X >= line2Point2X) {
                    return true
                } else {
                    return false
                }
            } else {
                if (line2Point1Y <= line1Point2Y) && (line1Point2Y <= line2Point2Y) {
                    return true
                } else if (line2Point1Y >= line1Point2Y) && (line1Point2Y >= line2Point2Y) {
                    return true
                } else {
                    return false
                }
            }
        }
        return ((area1 > 0.0) != (area2 > 0.0)) && ((area3 > 0.0) != (area4 > 0.0))
    }
    
    static func lineSegmentIntersectsLineSegmentOld(line1Point1X: Float,
                                                 line1Point1Y: Float,
                                                 line1Point2X: Float,
                                                 line1Point2Y: Float,
                                                 line2Point1X: Float,
                                                 line2Point1Y: Float,
                                                 line2Point2X: Float,
                                                 line2Point2Y: Float) -> Bool {

        /*
        let maxX2 = max(line2Point1X, line2Point2X)
        let minX1 = min(line1Point1X, line1Point2X)
        if maxX2 < minX1 { return false }
        
        let maxY2 = max(line2Point1Y, line2Point2Y)
        let minY1 = min(line1Point1Y, line1Point2Y)
        if maxY2 < minY1 { return false }
        
        let minX2 = min(line2Point1X, line2Point2X)
        let maxX1 = max(line1Point1X, line1Point2X)
        if minX2 > maxX1 { return false }
        
        let minY2 = min(line2Point1Y, line2Point2Y)
        let maxY1 = max(line1Point1Y, line1Point2Y)
        if minY2 > maxY1 { return false }
        */
        
        let area1 = triangleArea(x1: line1Point1X,
                                 y1: line1Point1Y,
                                 x2: line1Point2X,
                                 y2: line1Point2Y,
                                 x3: line2Point1X,
                                 y3: line2Point1Y)
        if fabsf(area1) < Math.epsilon {
            if between(x1: line1Point1X,
                       y1: line1Point1Y,
                       x2: line1Point2X,
                       y2: line1Point2Y,
                       x3: line2Point1X,
                       y3: line2Point1Y) {
                return true
            } else {
                if triangleAreaAbsolute(x1: line1Point1X,
                                        y1: line1Point1Y,
                                        x2: line1Point2X,
                                        y2: line1Point2Y,
                                        x3: line2Point2X,
                                        y3: line2Point2Y) < Math.epsilon {
                    if between(x1: line2Point1X,
                               y1: line2Point1Y,
                               x2: line2Point2X,
                               y2: line2Point2Y,
                               x3: line1Point1X,
                               y3: line1Point1Y) {
                        return true
                    }
                    if between(x1: line2Point1X,
                               y1: line2Point1Y,
                               x2: line2Point2X,
                               y2: line2Point2Y,
                               x3: line1Point2X,
                               y3: line1Point2Y) {
                        return true
                    }
                    return false
                }
                return false
            }
        }
        let area2 = triangleArea(x1: line1Point1X,
                                 y1: line1Point1Y,
                                 x2: line1Point2X,
                                 y2: line1Point2Y,
                                 x3: line2Point2X,
                                 y3: line2Point2Y)
        if fabsf(area2) < Math.epsilon {
            return between(x1: line1Point1X,
                           y1: line1Point1Y,
                           x2: line1Point2X,
                           y2: line1Point2Y,
                           x3: line2Point2X,
                           y3: line2Point2Y)
        }
        let area3 = triangleArea(x1: line2Point1X,
                                 y1: line2Point1Y,
                                 x2: line2Point2X,
                                 y2: line2Point2Y,
                                 x3: line1Point1X,
                                 y3: line1Point1Y)
        if fabsf(area3) < Math.epsilon {
            if between(x1: line2Point1X,
                       y1: line2Point1Y,
                       x2: line2Point2X,
                       y2: line2Point2Y,
                       x3: line1Point1X,
                       y3: line1Point1Y) {
                return true
            } else {
                if triangleAreaAbsolute(x1: line2Point1X,
                                        y1: line2Point1Y,
                                        x2: line2Point2X,
                                        y2: line2Point2Y,
                                        x3: line1Point2X,
                                        y3: line1Point2Y) < Math.epsilon {
                    if between(x1: line1Point1X,
                               y1: line1Point1Y,
                               x2: line1Point2X,
                               y2: line1Point2Y,
                               x3: line2Point1X,
                               y3: line2Point1Y) {
                        return true
                    }
                    if between(x1: line1Point1X,
                               y1: line1Point1Y,
                               x2: line1Point2X,
                               y2: line1Point2Y,
                               x3: line2Point2X,
                               y3: line2Point2Y) {
                        return true
                    }
                    return false
                }
                return false
            }
        }
        let area4 = triangleArea(x1: line2Point1X,
                                 y1: line2Point1Y,
                                 x2: line2Point2X,
                                 y2: line2Point2Y,
                                 x3: line1Point2X,
                                 y3: line1Point2Y)
        if fabsf(area4) < Math.epsilon {
            return between(x1: line2Point1X,
                           y1: line2Point1Y,
                           x2: line2Point2X,
                           y2: line2Point2Y,
                           x3: line1Point2X,
                           y3: line1Point2Y)
        }
        return ((area1 > 0.0) != (area2 > 0.0)) && ((area3 > 0.0) != (area4 > 0.0))
    }
    
    static func lineSegmentIntersectsLineSegment(line1Point1: Point,
                                                 line1Point2: Point,
                                                 line2Point1: Point,
                                                 line2Point2: Point) -> Bool {

        let maxX2 = max(line2Point1.x, line2Point2.x)
        let minX1 = min(line1Point1.x, line1Point2.x)
        if maxX2 < minX1 { return false }
        
        let maxY2 = max(line2Point1.y, line2Point2.y)
        let minY1 = min(line1Point1.y, line1Point2.y)
        if maxY2 < minY1 { return false }
        
        let minX2 = min(line2Point1.x, line2Point2.x)
        let maxX1 = max(line1Point1.x, line1Point2.x)
        if minX2 > maxX1 { return false }
        
        let minY2 = min(line2Point1.y, line2Point2.y)
        let maxY1 = max(line1Point1.y, line1Point2.y)
        if minY2 > maxY1 { return false }
        
        let area1 = triangleArea(x1: line1Point1.x, y1: line1Point1.y, x2: line1Point2.x, y2: line1Point2.y, x3: line2Point1.x, y3: line2Point1.y)
        if fabsf(area1) < Math.epsilon {
            if between(x1: line1Point1.x, y1: line1Point1.y, x2: line1Point2.x, y2: line1Point2.y, x3: line2Point1.x, y3: line2Point1.y) {
                return true
            } else {
                if fabsf(triangleArea(x1: line1Point1.x, y1: line1Point1.y, x2: line1Point2.x, y2: line1Point2.y, x3: line2Point2.x, y3: line2Point2.y)) < Math.epsilon {
                    if between(x1: line2Point1.x, y1: line2Point1.y, x2: line2Point2.x, y2: line2Point2.y, x3: line1Point1.x, y3: line1Point1.y) {
                        return true
                    }
                    if between(x1: line2Point1.x, y1: line2Point1.y, x2: line2Point2.x, y2: line2Point2.y, x3: line1Point2.x, y3: line1Point2.y) {
                        return true
                    }
                    return false
                }
                return false
            }
        }
        let area2 = triangleArea(x1: line1Point1.x, y1: line1Point1.y, x2: line1Point2.x, y2: line1Point2.y, x3: line2Point2.x, y3: line2Point2.y)
        if fabsf(area2) < Math.epsilon {
            return between(x1: line1Point1.x, y1: line1Point1.y, x2: line1Point2.x, y2: line1Point2.y, x3: line2Point2.x, y3: line2Point2.y)
        }
        let area3 = triangleArea(x1: line2Point1.x, y1: line2Point1.y, x2: line2Point2.x, y2: line2Point2.y, x3: line1Point1.x, y3: line1Point1.y)
        if fabsf(area3) < Math.epsilon {
            if between(x1: line2Point1.x, y1: line2Point1.y, x2: line2Point2.x, y2: line2Point2.y, x3: line1Point1.x, y3: line1Point1.y) {
                return true
            } else {
                if fabsf(triangleArea(x1: line2Point1.x, y1: line2Point1.y, x2: line2Point2.x, y2: line2Point2.y, x3: line1Point2.x, y3: line1Point2.y)) < Math.epsilon {
                    if between(x1: line1Point1.x, y1: line1Point1.y, x2: line1Point2.x, y2: line1Point2.y, x3: line2Point1.x, y3: line2Point1.y) {
                        return true
                    }
                    if between(x1: line1Point1.x, y1: line1Point1.y, x2: line1Point2.x, y2: line1Point2.y, x3: line2Point2.x, y3: line2Point2.y) {
                        return true
                    }
                    return false
                }
                return false
            }
        }
        let area4 = triangleArea(x1: line2Point1.x, y1: line2Point1.y, x2: line2Point2.x, y2: line2Point2.y, x3: line1Point2.x, y3: line1Point2.y)
        if fabsf(area4) < Math.epsilon {
            return between(x1: line2Point1.x, y1: line2Point1.y, x2: line2Point2.x, y2: line2Point2.y, x3: line1Point2.x, y3: line1Point2.y)
        }
        return ((area1 > 0.0) != (area2 > 0.0)) && ((area3 > 0.0) != (area4 > 0.0))
    }
    
    static func lineSegmentShortestConnectingLineSegmentToLineSegment(line1Point1: Point, line1Point2: Point, line2Point1: Point, line2Point2: Point) -> (point1: Point, point2: Point) {
        let cp1_1 = Math.segmentClosestPoint(point: line1Point1, linePoint1: line2Point1, linePoint2: line2Point2)
        let cp1_2 = Math.segmentClosestPoint(point: line1Point2, linePoint1: line2Point1, linePoint2: line2Point2)
        let cp2_1 = Math.segmentClosestPoint(point: line2Point1, linePoint1: line1Point1, linePoint2: line1Point2)
        let cp2_2 = Math.segmentClosestPoint(point: line2Point2, linePoint1: line1Point1, linePoint2: line1Point2)
        
        let distance0 = cp1_1.distanceSquaredTo(cp2_1)
        let distance1 = cp1_1.distanceSquaredTo(cp2_2)
        let distance2 = cp1_2.distanceSquaredTo(cp2_1)
        let distance3 = cp1_2.distanceSquaredTo(cp2_2)
        
        var chosenDistance = distance0
        var chosenIndex = 0
        if distance1 < chosenDistance {
            chosenIndex = 1
            chosenDistance = distance1
        }
        if distance2 < chosenDistance {
            chosenIndex = 2
            chosenDistance = distance2
        }
        if distance3 < chosenDistance {
            chosenIndex = 3
        }
        
        if chosenIndex == 0 {
            return (cp2_1, cp1_1)
        } else if chosenIndex == 1 {
            return (cp2_2, cp1_1)
        } else if chosenIndex == 2 {
            return (cp2_1, cp1_2)
        } else {
            return (cp2_2, cp1_2)
        }
    }
    
    static func lineSegmentDistanceSquaredToLineSegment(line1Point1: Point, line1Point2: Point, line2Point1: Point, line2Point2: Point) -> Float {
        
        if lineSegmentIntersectsLineSegment(line1Point1: line1Point1,
                                            line1Point2: line1Point2,
                                            line2Point1: line2Point1,
                                            line2Point2: line2Point2) {
            return 0.0
        }
        
        let cp1_1 = Math.segmentClosestPoint(point: line1Point1, linePoint1: line2Point1, linePoint2: line2Point2)
        let cp1_2 = Math.segmentClosestPoint(point: line1Point2, linePoint1: line2Point1, linePoint2: line2Point2)
        let cp2_1 = Math.segmentClosestPoint(point: line2Point1, linePoint1: line1Point1, linePoint2: line1Point2)
        let cp2_2 = Math.segmentClosestPoint(point: line2Point2, linePoint1: line1Point1, linePoint2: line1Point2)
        
        let distance0 = cp1_1.distanceSquaredTo(cp2_1)
        let distance1 = cp1_1.distanceSquaredTo(cp2_2)
        let distance2 = cp1_2.distanceSquaredTo(cp2_1)
        let distance3 = cp1_2.distanceSquaredTo(cp2_2)
        
        var chosenDistance = distance0
        if distance1 < chosenDistance { chosenDistance = distance1 }
        if distance2 < chosenDistance { chosenDistance = distance2 }
        if distance3 < chosenDistance { chosenDistance = distance3 }
        return chosenDistance
    }
    
    static func dot(x1: Float, y1: Float, x2: Float, y2: Float) -> Float {
        x1 * x2 + y1 * y2
    }
    
    static func cross(x1: Float, y1: Float, x2: Float, y2: Float) -> Float {
        x1 * y2 - x2 * y1
    }
    
    static func triangleIsClockwise(x1: Float, y1: Float,
                                    x2: Float, y2: Float,
                                    x3: Float, y3: Float) -> Bool {
        if (x1 * y2 + x3 * y1 + x2 * y3 - x1 * y3 - x3 * y2 - x2 * y1) > 0.0 {
            return false
        } else {
            return true
        }
    }
    
    static func polygonIsClockwise(_ polygon: [Point]) -> Bool {
        var area = Float(0.0)
        var index1 = polygon.count - 1
        var index2 = 0
        while index2 < polygon.count {
            let point1 = polygon[index1]
            let point2 = polygon[index2]
            area += Math.cross(x1: point1.x, y1: point1.y,
                               x2: point2.x, y2: point2.y)
            index1 = index2
            index2 += 1
        }
        return area > 0.0
    }
    
    static func polygonIsCounterClockwise(_ points: [Point]) -> Bool {
        return !polygonIsClockwise(points)
    }
    
    static func polygonIndexDistance(index1: Int, index2: Int, count: Int) -> Int {
        let larger = max(index1, index2)
        let smaller = min(index1, index2)
        let choice1 = larger - smaller
        let choice2 = ((count) - larger) + (smaller)
        return min(choice1, choice2)
    }
    
    static func polygonTourCrosses(index: Int, startIndex: Int, endIndex: Int) -> Bool {
        if startIndex == endIndex {
            if index == startIndex {
                return true
            }
        } else {
            if startIndex < endIndex {
                if index >= startIndex && index <= endIndex {
                    return true
                }
            } else {
                if index >= startIndex {
                    return true
                }
                if index <= endIndex {
                    return true
                }
            }
        }
        return false
    }
    
    static func polygonTourLength(startIndex: Int, endIndex: Int, count: Int) -> Int {
        if startIndex == endIndex {
            return 1
        } else {
            if startIndex < endIndex {
                return (endIndex - startIndex) + 1
            } else {
                return (count - startIndex) + (endIndex) + 1
            }
        }
    }
    
    static func polygonTourLength(index: Int, startIndex: Int, endIndex: Int, count: Int) -> Int? {
        if startIndex == endIndex {
            if index == startIndex {
                return 1
            }
        } else {
            if startIndex < endIndex {
                if index >= startIndex && index <= endIndex {
                    return (index - startIndex) + 1
                }
            } else {
                if index >= startIndex {
                    return (index - startIndex) + 1
                }
                if index <= endIndex {
                    return (count - startIndex) + (index) + 1
                }
            }
        }
        return nil
    }
    
    static func polygonIsComplex(_ polygon: [Point]) -> Bool {
        let count = polygon.count
        if count > 3 {
            let count_2 = (count - 2)
            let count_1 = (count - 1)
            var outerMinusOne = 0
            var outer = 1
            while outer < count_2 {
                var innerMinusOne = outer + 1
                var inner = innerMinusOne + 1
                while inner < count {
                    if Math.lineSegmentIntersectsLineSegment(line1Point1: polygon[outerMinusOne], line1Point2: polygon[outer],
                                                             line2Point1: polygon[innerMinusOne], line2Point2: polygon[inner]) {
                        return true
                    }
                    innerMinusOne = inner
                    inner += 1
                }
                outerMinusOne = outer
                outer += 1
            }
            outerMinusOne = 1
            outer = 2
            while outer < count_1 {
                if Math.lineSegmentIntersectsLineSegment(line1Point1: polygon[count_1], line1Point2: polygon[0],
                                                         line2Point1: polygon[outerMinusOne], line2Point2: polygon[outer]) {
                    return true
                }
                outerMinusOne = outer
                outer += 1
            }
        }
        return false
    }
    
    static func polygonIsSimple(_ polygon: [Point]) -> Bool {
        return !polygonIsComplex(polygon)
    }
    
    static func polygonContainsPoint(_ polygon: [Point], _ point: Point) -> Bool {
        
        let result1 = polygonContainsPointNew(polygon, point)
        let result2 = polygonContainsPointOld(polygon, point)
        if result1 != result2 {
            print("MISMATCH PCP: \(result1), \(result2)")
            print(polygon)
            print(point)
        }
        return result2
    }
    
    static func polygonContainsPointNew(_ polygon: [Point], _ point: Point) -> Bool {
        var end = polygon.count - 1
        var start = 0
        var result = false
        while start < polygon.count {
            
            let point1 = polygon[start]
            let point2 = polygon[end]
            
            let x1: Float
            let y1: Float
            let x2: Float
            let y2: Float
            if point1.x < point2.x {
                x1 = point1.x
                y1 = point1.y
                x2 = point2.x
                y2 = point2.y
            } else {
                x1 = point2.x
                y1 = point2.y
                x2 = point1.x
                y2 = point1.y
            }
            if point.x > x1 && point.x <= x2 {
                if (point.x - x1) * (y2 - y1) - (point.y - y1) * (x2 - x1) < 0.0 {
                    result = !result
                }
            }
            end = start
            start += 1
        }
        return result
    }
    
    static func polygonContainsPointOld(_ polygon: [Point], _ point: Point) -> Bool {
        var end = polygon.count - 1
        var start = 0
        var result = false
        while start < polygon.count {
            if (((polygon[start].y <= point.y ) && (point.y < polygon[end].y))
                || ((polygon[end].y <= point.y) && (point.y < polygon[start].y)))
                && (point.x < (polygon[end].x - polygon[start].x) * (point.y - polygon[start].y)
                    / (polygon[end].y - polygon[start].y) + polygon[start].x) {
                result = !result
            }
            end = start
            start += 1
        }
        return result
    }
    
    static func triangleCentroid(point1: Point, point2: Point, point3: Point) -> Point {
        var result = Point(x: 0.0, y: 0.0)
        var area = Float(0.0)
        
        let cross1 = Math.cross(x1: point1.x, y1: point1.y,
                               x2: point2.x, y2: point2.y)
        area += cross1
        result.x += (point1.x + point2.x) * cross1
        result.y += (point1.y + point2.y) * cross1
        
        let cross2 = Math.cross(x1: point2.x, y1: point3.y,
                               x2: point2.x, y2: point3.y)
        area += cross2
        result.x += (point2.x + point3.x) * cross2
        result.y += (point2.y + point3.y) * cross2
        
        
        let cross3 = Math.cross(x1: point3.x, y1: point1.y,
                               x2: point3.x, y2: point1.y)
        area += cross3
        result.x += (point3.x + point1.x) * cross3
        result.y += (point3.y + point1.y) * cross3
        
        if area > Math.epsilon || area < Math._epsilon {
            area *= 3.0
            result.x /= area
            result.y /= area
        }
        return result
    }
    
    
    static func polygonCentroid(_ polygon: [Point]) -> Point {
        var result = Point(x: 0.0, y: 0.0)
        var area = Float(0.0)
        
        var index1 = polygon.count - 1
        var index2 = 0
        while index2 < polygon.count {
            let point1 = polygon[index1]
            let point2 = polygon[index2]
            let cross = Math.cross(x1: point1.x, y1: point1.y,
                                   x2: point2.x, y2: point2.y)
            area += cross
            
            result.x += (point1.x + point2.x) * cross
            result.y += (point1.y + point2.y) * cross
            
            index1 = index2
            index2 += 1
        }
        
        if area > Math.epsilon || area < Math._epsilon {
            area *= 3.0
            result.x /= area
            result.y /= area
        }
        return result
    }

    static func circleIntersectsCircle(circle1Center: Point, circle1Radius: Float, circle2Center: Point, circle2Radius: Float) -> Bool {
        let radiusSum = circle1Radius + circle2Radius
        return circle1Center.distanceSquaredTo(circle2Center) <= (radiusSum * radiusSum)
    }
}
