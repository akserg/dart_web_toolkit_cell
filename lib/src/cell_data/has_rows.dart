//Copyright (C) 2013 Sergey Akopkokhyants. All Rights Reserved.
//Author: akserg

/**
 * Data presentation widgets for the Dart Web Toolkit.
 */
part of dart_web_toolkit_cell_data;

/**
 * Describes an object that displays a range of rows.
 */
abstract class HasRows extends event.HasHandlers {

  /**
   * Add a {@link RangeChangeEvent.Handler}.
   *
   * @param handler the handler
   * @return a {@link event.HandlerRegistration} to remove the handler
   */
  event.HandlerRegistration addRangeChangeHandler(RangeChangeEventHandler handler);

  /**
   * Add a {@link RowCountChangeEvent.Handler}.
   *
   * @param handler the handler
   * @return a {@link event.HandlerRegistration} to remove the handler
   */
  event.HandlerRegistration addRowCountChangeHandler(RowCountChangeEventHandler handler);

  /**
   * Get the total count of all rows.
   *
   * @return the total row count
   *
   * @see #setRowCount(int)
   */
  int getRowCount();

  /**
   * Get the range of visible rows.
   *
   * @return the visible range
   * 
   * @see #setVisibleRange(Range)
   * @see #setVisibleRange(int, int)
   */
  Range getVisibleRange();

  /**
   * Check if the total row count is exact, or an estimate.
   *
   * @return true if exact, false if an estimate
   */
  bool isRowCountExact();

  /**
   * Set the total count of all rows, specifying whether the count is exact or
   * an estimate.
   *
   * @param count the total count
   * @param isExact true if the count is exact, false if an estimate
   * @see #getRowCount()
   */
  void setRowCount(int count, [bool isExact = true]);

  /**
   * Set the visible range or rows. This method defers to
   * {@link #setVisibleRange(Range)}.
   *
   * @param start the start index
   * @param length the length
   *
   * @see #getVisibleRange()
   */
  // TODO(jlabanca): Should we include setPageStart/Size as shortcut methods?
  void setVisibleRange(int start, int length);

  /**
   * Set the visible range or rows.
   *
   * @param range the visible range
   *
   * @see #getVisibleRange()
   */
  void setVisibleRangeByRange(Range range);
}