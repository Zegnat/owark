/**
 * Copyright (C) 2012 Eric van der Vlist.
 *
 * This program is free software; you can redistribute it and/or modify it under the terms of the
 * GNU Lesser General Public License as published by the Free Software Foundation; either version
 * 2.1 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
 * without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU Lesser General Public License for more details.
 *
 * The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
 */
package org.owark.warc;

/**
 * Created by IntelliJ IDEA.
 * User: vdv
 * Date: 25 avr. 2012
 * Time: 17:56:22
 * To change this template use File | Settings | File Templates.
 */
public class WarcField {


    private String line;
    private String key;
    private String value;

    public WarcField(String line) {
        this.line = line;
        int sep = line.indexOf(":");
        this.key = line.substring(0, sep).trim();
        this.value = line.substring(sep + 1).trim();
    }

    public String getKey() {
        return key;
    }

    public String getLine() {
        return line;
    }

    public String getValue() {
        return value;
    }

}
