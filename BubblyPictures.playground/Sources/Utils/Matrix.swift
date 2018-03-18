import Foundation
import CoreGraphics.CGBase

/// A structure used to contain a matrix of arbitrary size.
/// Shoutout to Apple Documentation @ Subscript @ Subscript Options for inspiration.
/// - Warning: Elements on the matrix are created dynamically and sequentially. This means that
///            you cannot perform assignments on random positions which aren't initialized yet!
struct Matrix<Element>: Sequence {
    /// The size of this matrix.
    public let size: MatrixSize
    
    // While thinking about how to implement a matrix, fundamental to this playground, the most
    // important dilemma was whether to use a one-dimensional array or a two-dimensional one.
    // To aid my decision, I performed some research, and found this fantastic piece of work
    // by Pixelchemist: http://stackoverflow.com/a/17260533
    // While it's indeed true that the answer is about C and C++, and Swift is obviously more
    // optimized in that sense, I still believe that better performance is achieved using a 1D
    // array, and that is the reason why I'm using it here.
    var storage: [Element] = []
    
    /// The total count of the elements.
    var count: Int {
        return self.storage.count
    }
    
    /// Initializes a new matrix with a maximum of rows * columns elements.
    ///
    /// - Parameters:
    ///   - rows: The number of available rows.
    ///   - columns: The number of available columns.
    init (rows: Int, columns: Int) {
        // Update our internal count of rows and columns.
        self.size = MatrixSize(rows: rows, columns: columns)
    }
    
    /// Returns a boolean value indicating whether this matrix contains the specified coordinates.
    ///
    /// - Parameters:
    ///   - row: Row number (starting from `0`)
    ///   - column: Column number (starting from `0`)
    /// - Returns: `true` if the matrix contains the coordinates, `false` otherwise.
    func hasCoordinate (row: Int, column: Int) -> Bool {
        return row * self.size.columns + column < self.storage.count
    }
    
    /// Returns a boolean value indicating whether this matrix contains the specified coordinates.
    ///
    /// - Parameter coordinate: An object containing a pair of coordinates.
    /// - Returns: `true` if the matrix contains the coordinates, `false` otherwise.
    func hasCoordinate (_ coordinate: MatrixCoordinate) -> Bool {
        return self.hasCoordinate (row: coordinate.row, column: coordinate.column)
    }
    
    /// Accesses an element of the matrix.
    ///
    /// - Parameters:
    ///   - row: Row number (starting from `0`).
    ///   - column: Column number (starting from `0`).
    /// - Warning: If the element does not exist (for accessing) or its previous does not exist
    ///   (for setting), an illegal access will occur and your program will terminate.
    subscript (row: Int, column: Int) -> Element {
        get {
            return self.storage[row * self.size.columns + column]
        }
        set {
            self.storage.insert(newValue, at: row * self.size.columns + column)
        }
    }
    
    /// Accesses an element of the matrix.
    ///
    /// - Parameter coordinates: An object containing a pair of coordinates.
    /// - Warning: If the element does not exist (for accessing) or its previous does not exist
    ///   (for setting), an illegal access will occur and your program will terminate.
    subscript (coordinates: MatrixCoordinate) -> Element {
        get { return self[coordinates.row, coordinates.column] }
        set { self[coordinates.row, coordinates.column] = newValue }
    }
    
    // MARK: Sequence
    func makeIterator() -> MatrixIterator<Element> {
        return MatrixIterator(self)
    }
}

/// An Iterator object which provides iteration support for a `Matrix` object.
struct MatrixIterator<Element>: IteratorProtocol {
    private let matrix: Matrix<Element>
    private var position: MatrixCoordinate = .zero
    
    fileprivate init (_ matrix: Matrix<Element>) {
        self.matrix = matrix
    }
    
    // MARK: IteratorProtocol
    mutating func next() -> (position: MatrixCoordinate, element: Element)? {
        // Try to access the current position, and if we fail, return nil to the caller.
        guard self.matrix.hasCoordinate (self.position) else {
            return nil
        }
        let result = (position: self.position, element: self.matrix[self.position])
        // Increase the current coordinates.
        self.position.advance (withMatrixOfColumns: self.matrix.size.columns)
        // We're done!
        return result
    }
}

/// An object which contains the dimensions of a matrix.
///
/// This object can be iterated over to provide a convenient way to populate matrixes.
struct MatrixSize: CustomStringConvertible, Sequence {
    /// The total number of rows/columns of this matrix.
    let rows: Int, columns: Int
    
    /// The complete number of elements this matrix can hold.
    var total: Int {
        return rows * columns
    }
    
    // MARK: CustomStringConvertible
    var description: String {
        return "{\(self.rows), \(self.columns)}"
    }
    
    // MARK: Sequence
    func makeIterator() -> MatrixSizeIterator {
        return MatrixSizeIterator(self)
    }
}

/// An Iterator object which provides iteration support for a `MatrixSize` object.
struct MatrixSizeIterator: IteratorProtocol {
    private let matrixSize: MatrixSize
    private var position: MatrixCoordinate = .zero
    
    fileprivate init (_ size: MatrixSize) {
        self.matrixSize = size
    }
    
    // MARK: IteratorProtocol
    mutating func next() -> MatrixCoordinate? {
        // Stop right now if the position we're pointing at is invalid.
        guard self.position.row < self.matrixSize.rows,
            self.position.column < self.matrixSize.columns else {
            return nil
        }
        // Advance the current position and return the old one.
        let position = self.position
        self.position.advance (withMatrixOfColumns: self.matrixSize.columns)
        return position
    }
}

/// An object which contains coordinates pointing to an element in a matrix.
struct MatrixCoordinate: CustomStringConvertible {
    /// The coordinate with location `(0, 0)`.
    static public var zero = MatrixCoordinate (row: 0, column: 0)
    
    /// The row/column number usable to access an element of a matrix.
    public var row: Int, column: Int
    
    /// Advances this `MatrixCoordinate` object by one column.
    ///
    /// If the total number of columns (specified with the `columns` parameter) is reached,
    /// the column number is reset to `0` and the row number is increased by `1`.
    ///
    /// - Parameter columns: The total columns of a matrix associated with this object.
    mutating func advance (withMatrixOfColumns columns: Int) {
        self.column += 1
        if self.column == columns {
            self.column = 0
            self.row   += 1
        }
    }
    
    /// A representation of this object as a `CGPoint`.
    public var cgPoint: CGPoint {
        return CGPoint(x: self.row, y: self.column)
    }
    
    // MARK: CustomStringConvertible
    var description: String {
        return "(\(self.row), \(self.column))"
    }
}
