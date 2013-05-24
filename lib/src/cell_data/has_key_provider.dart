//Copyright (C) 2013 Sergey Akopkokhyants. All Rights Reserved.
//Author: akserg

/**
 * Data presentation widgets for the Dart Web Toolkit.
 */
part of dart_web_toolkit_cell_data;

/**
 * Interface for classes that have a {@link ProvidesKey}. Must be implemented by
 * {@link com.google.gwt.cell.client.Cell} containers.
 *
 * @param <T> the data type
 */
abstract class HasKeyProvider<T> {

  /**
   * Return the key provider.
   *
   * @return the {@link ProvidesKey} instance
   */
  data.ProvidesKey<T> getKeyProvider();
}
