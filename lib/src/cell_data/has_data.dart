//Copyright (C) 2013 Sergey Akopkokhyants. All Rights Reserved.
//Author: akserg

/**
 * Data presentation widgets for the Dart Web Toolkit.
 */
part of dart_web_toolkit_cell_data;

/**
 * A view that can display a range of data.
 * 
 * @param <T> the data type of each row
 */
abstract class HasData<T> implements HasRows, HasCellPreviewHandlers<T> {

  /**
   * Get the {@link SelectionModel} used by this {@link HasData}.
   * 
   * @return the {@link SelectionModel}
   * 
   * @see #setSelectionModel(SelectionModel)
   */
  SelectionModel<T> getSelectionModel();

  /**
   * Get the row value at the specified visible index. Index 0 corresponds to
   * the first item on the page.
   * 
   * @param indexOnPage the index on the page
   * @return the row value
   */
  T getVisibleItem(int indexOnPage);

  /**
   * Get the number of visible items being displayed. Note that this value might
   * be less than the page size if there is not enough data to fill the page.
   * 
   * @return the number of visible items on the page
   */
  int getVisibleItemCount();

  /**
   * Get an {@link Iterable} composed of all of the visible items.
   * 
   * @return an {@link Iterable} instance
   */
  Iterable<T> getVisibleItems();

  /**
   * <p>
   * Set a values associated with the rows in the visible range.
   * </p>
   * <p>
   * This method <i>does not</i> replace all rows in the display; it replaces
   * the row values starting at the specified start index through the length of
   * the the specified values. You must call {@link #setRowCount(int)} to set
   * the total number of rows in the display. You should also use
   * {@link #setRowCount(int)} to remove rows when the total number of rows
   * decreases.
   * </p>
   * 
   * @param start the start index of the data
   * @param values the values within the range
   */
  void setRowData(List<T> values, [int start = null]);

  /**
   * Set the {@link SelectionModel} used by this {@link HasData}.
   * 
   * @param selectionModel the {@link SelectionModel}
   * 
   * @see #getSelectionModel()
   */
  void setSelectionModel(SelectionModel<T> selectionModel);

  /**
   * <p>
   * Set the visible range and clear the current visible data.
   * </p>
   * <p>
   * If the second argument <code>forceRangeChangeEvent</code> is true, a
   * {@link RangeChangeEvent} will be fired even if the range does not change.
   * If false, a {@link RangeChangeEvent} will only be fired if the range
   * changes.
   * </p>
   * 
   * @param range the new {@link Range}
   * @param forceRangeChangeEvent true to fire a {@link RangeChangeEvent} even
   *          if the {@link Range} doesn't change
   */
  void setVisibleRangeAndClearData(Range range, bool forceRangeChangeEvent);
}