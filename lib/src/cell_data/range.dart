//Copyright (C) 2013 Sergey Akopkokhyants. All Rights Reserved.
//Author: akserg

/**
 * Data presentation widgets for the Dart Web Toolkit.
 */
part of dart_web_toolkit_cell_data;

/**
 * The range of interest for a single handler.
 */
class Range extends Object {

  int _length;
  int _start;

  /**
   * Construct a new {@link Range}.
   *
   * @param _start the start index
   * @param _length the length
   */
  Range(this._start, this._length);

  /**
   * Return true if this ranges's start end length are equal to those of
   * the given object.
   */
  bool operator ==(Range o) {
    return _start == o.getStart() && _length == o.getLength();
  }

  /**
   * Get the length of the range.
   *
   * @return the length
   */
  int getLength() {
    return _length;
  }

  /**
   * Get the start index of the range.
   *
   * @return the start index
   */
  int getStart() {
    return _start;
  }

  /**
   * Returns a String representation for debugging.
   */
  String toString() {
    return "Range(%_start,%_length)";
  }
}