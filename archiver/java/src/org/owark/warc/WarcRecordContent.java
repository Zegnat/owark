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

import java.io.IOException;
import java.io.InputStream;
import java.util.Iterator;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Created by IntelliJ IDEA.
 * User: vdv
 * Date: 25 avr. 2012
 * Time: 19:00:47
 * To change this template use File | Settings | File Templates.
 */
public class WarcRecordContent extends InputStream implements Iterator<WarcField>  {

    private WarcRecord warcRecord;
    private Exception e;
    private String line;
    private String payloadContentType;

    public WarcRecordContent(WarcRecord warcRecord) {
        this.warcRecord = warcRecord;
    }

    public boolean hasFields() {
        return warcRecord.getContentType().equals("application/warc-fields") || isHTTP();
    }

    public boolean hasNext() {
        try {
            line = warcRecord.readLine();
        } catch (Exception e) {
            this.e = e;
        }
        return ! (warcRecord.isLimitReached() || line.equals(""));
    }

    public WarcField next() {
        if (line == null) {
            try {
                line = warcRecord.readLine();
            } catch (Exception e) {
                this.e = e;
            }
        }
        if (line.equals("")) {
            line = null;
            return null;
        }
        WarcField field = new WarcField(line);
        if (field.getKey().equals("Content-Type")) {
            this.payloadContentType = field.getValue();
        }
        line = null;
        return field;
    }

    public void remove() {
        //To change body of implemented methods use File | Settings | File Templates.
    }

    @Override
    public int read() throws IOException {
        return warcRecord.read();
    }

    public boolean isHTTP() {
        return warcRecord.getContentType().startsWith("application/http");
    }

    public boolean isRequest() {
        return warcRecord.getType().equals("request");
    }

    public HttpStatusLine getStatusLine() throws IOException, WarcParser.WarcException {
        return new HttpStatusLine(warcRecord.readLine());
    }

    public boolean hasStatusLine() {
        return isHTTP() && ! isRequest();
    }

    public boolean hasRequestLine() {
        return isHTTP() && isRequest();
    }

    public boolean endOfContent() {
        return warcRecord.isLimitReached();
    }

    public HttpRequestLine getRequestLine() throws IOException, WarcParser.WarcException {
        return new HttpRequestLine(warcRecord.readLine());
    }

    public long getContentLength() {
        return warcRecord.getContentLength();
    }

    public String getPayloadContentType() {
        String contentType = getPayloadContentHeader();
        if (contentType != null && contentType.contains(";")) {
            contentType = contentType.substring(0, contentType.indexOf(";"));
        }
        return contentType;
    }

    public String getPayloadContentHeader() {
        String contentType = warcRecord.getContentType();
        if (contentType.equals("application/warc-fields") || contentType.equals("application/http; msgtype=request")) {
            return null;
        }
        if (contentType.equals("application/http; msgtype=response")) {
            contentType = this.payloadContentType;
        }
        return contentType;
    }

    public String getPayloadEncoding() {
        String contentType = getPayloadContentHeader();
        if (contentType == null) {
            return contentType;
        }
        Pattern pattern = Pattern.compile(".*;\\s*charset\\s*=\\s*([^;]+).*");
        Matcher matcher = pattern.matcher(contentType);
        if (matcher.matches()) {
            return matcher.group(1).toLowerCase();
        }
        return null;
     }


    public class HttpStatusLine {

        private String line;
        private String version;
        private String status;
        private String reason;
        

        public String getLine() {
            return line;
        }

        public String getVersion() {
            return version;
        }

        public String getStatus() {
            return status;
        }

        public String getReason() {
            return reason;
        }


        protected HttpStatusLine(String line) {
            this.line = line;
            String[] tokens = line.split(" ", 3);
            this.version = tokens[0];
            this.status = tokens[1];
            this.reason = tokens[2];
        }
        
    }

    public class HttpRequestLine {

        private String line;
        private String version;
        private String method;
        private String uri;

        public String getLine() {
            return line;
        }

        public String getVersion() {
            return version;
        }

        public String getMethod() {
            return method;
        }

        public String getUri() {
            return uri;
        }

        public HttpRequestLine(String line) {
            this.line = line;
            String[] tokens = line.split(" ", 3);
            this.method = tokens[0];
            this.uri = tokens[1];
            this.version = tokens[2];
        }
    }
}

