final class GridCell {
  final int col;
  final int row;

  const GridCell(this.col, this.row);

  @override
  bool operator ==(Object other) {
    return other is GridCell && other.col == col && other.row == row;
  }

  @override
  int get hashCode => Object.hash(col, row);
}
