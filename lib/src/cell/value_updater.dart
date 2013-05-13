//Copyright (C) 2013 Sergey Akopkokhyants. All Rights Reserved.
//Author: akserg

/**
 * Data presentation widgets for the Dart Web Toolkit.
 */
part of dart_web_toolkit_cell;

/**
 * A {@link ValueUpdater} may be added to a {@link Cell} to provide updated
 * data.
 * 
 * @param <C> the data type of the cell
 */
abstract class ValueUpdater<C> {

  /**
   * Announces a new value.
   * 
   * @param value the updated value
   */
  void update(C value);
}