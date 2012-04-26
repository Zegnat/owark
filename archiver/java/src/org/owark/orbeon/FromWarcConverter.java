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
package org.owark.orbeon;

import org.apache.commons.fileupload.FileItem;
import org.orbeon.oxf.pipeline.api.PipelineContext;
import org.orbeon.oxf.pipeline.api.XMLReceiver;
import org.orbeon.oxf.processor.ProcessorImpl;
import org.orbeon.oxf.processor.ProcessorInputOutputInfo;
import org.orbeon.oxf.processor.ProcessorOutput;
import org.orbeon.oxf.processor.ProcessorUtils;
import org.orbeon.oxf.processor.serializer.BinaryTextXMLReceiver;
import org.orbeon.oxf.util.NetUtils;
import org.orbeon.oxf.xml.ContentHandlerHelper;
import org.orbeon.oxf.xml.XMLConstants;
import org.orbeon.oxf.xml.XMLUtils;
import org.owark.warc.*;
import org.xml.sax.Attributes;
import org.xml.sax.helpers.AttributesImpl;

import java.io.BufferedInputStream;
import java.io.IOException;
import java.io.InputStreamReader;

/**
 * This processor converts a WARC archive into an XML representation
 */

public class FromWarcConverter extends ProcessorImpl {

    static public String WARC_ELEMENT_ROOT_NAME     = "warc";
    static public String RECORD_ELEMENT_NAME        = "record";
    static public String HEADERS_ELEMENT_NAME       = "headers";
    static public String HEADER_ELEMENT_NAME        = "header";
    static public String NAME_ATTRIBUTE_NAME         = "name";
    static public String CONTENT_ELEMENT_NAME       = "content";

    public FromWarcConverter() {
        addInputInfo(new ProcessorInputOutputInfo(INPUT_DATA));
        addOutputInfo(new ProcessorInputOutputInfo(OUTPUT_DATA));
    }

    @Override
    public ProcessorOutput createOutput(String outputName) {
        final ProcessorOutput output = new ProcessorOutputImpl(FromWarcConverter.this,outputName) {

            @Override
            protected void readImpl(PipelineContext pipelineContext, XMLReceiver xmlReceiver) {
                // Get FileItem
                try {
                    ContentHandlerHelper helper = new ContentHandlerHelper(xmlReceiver);
                    helper.startDocument();
                    helper.startElement(WARC_ELEMENT_ROOT_NAME);
                    final FileItem fileItem = NetUtils.prepareFileItem(NetUtils.REQUEST_SCOPE);
                    // Read to OutputStream
                    readInputAsSAX(pipelineContext, INPUT_DATA, new BinaryTextXMLReceiver(null, fileItem.getOutputStream(), true, false, null, false, false, null, false));
                    // as an archive                    
                    final WarcParser warcParser =  new WarcParser(fileItem.getInputStream());
                    while (warcParser.hasNext()) {
                        helper.startElement(RECORD_ELEMENT_NAME);
                        helper.startElement(HEADERS_ELEMENT_NAME);
                        WarcRecord record = warcParser.next();
                        WarcRecordHeader recordHeader = record.getHeader();
                        while (recordHeader.hasNext()) {
                            WarcField field = recordHeader.next();
                            helper.startElement(HEADER_ELEMENT_NAME, new String[] {NAME_ATTRIBUTE_NAME, field.getKey()});
                            helper.text(field.getValue());
                            helper.endElement();
                        }
                        helper.endElement();
                        helper.startElement(CONTENT_ELEMENT_NAME);
                        WarcRecordContent content = record.getContent();
                        if (content.hasRequestLine()) {
                            helper.startElement("request");
                            WarcRecordContent.HttpRequestLine request = content.getRequestLine();
                            helper.element("method", request.getMethod());
                            helper.element("uri", request.getUri());
                            helper.element("version", request.getVersion());
                            helper.endElement();
                        } else if (content.hasStatusLine()) {
                            helper.startElement("status");
                            WarcRecordContent.HttpStatusLine status = content.getStatusLine();
                            helper.element("version", status.getVersion());
                            helper.element("status", status.getStatus());
                            helper.element("reason", status.getReason());
                            helper.endElement();
                        }
                        if (content.hasFields()) {
                            helper.startElement(HEADERS_ELEMENT_NAME);
                            while (content.hasNext()) {
                                WarcField field = content.next();
                                helper.startElement(HEADER_ELEMENT_NAME, new String[] {NAME_ATTRIBUTE_NAME, field.getKey()});
                                helper.text(field.getValue());
                                helper.endElement();
                            }
                            helper.endElement();
                        }
                        if (! content.endOfContent()) {
                            helper.startPrefixMapping("xsi", "http://www.w3.org/2001/XMLSchema-instance");
                            helper.startPrefixMapping("xs", "http://www.w3.org/2001/XMLSchema");
                            String contentType = content.getPayloadContentType();
                            AttributesImpl attributes = new AttributesImpl();
                            attributes.addAttribute("", "content-type", "content-type", "CDATA", contentType);
                            if (contentType.startsWith("text/") || contentType.matches(".*application/[^;]*xml.*")) {
                                attributes.addAttribute(XMLConstants.XSI_URI, "type", "xsi:type", "CDATA", "xs:string");
                                String encoding = content.getPayloadEncoding();
                                if (encoding == null) {
                                    encoding = "utf-8";
                                }
                                helper.startElement(ProcessorUtils.DEFAULT_TEXT_DOCUMENT_ELEMENT, attributes);
                                XMLUtils.readerToCharacters(new InputStreamReader(content, encoding), xmlReceiver);
                                helper.endElement();
                            } else {
                                attributes.addAttribute(XMLConstants.XSI_URI, "type", "xsi:type", "CDATA", "xs:base64Binary");
                                helper.startElement(ProcessorUtils.DEFAULT_BINARY_DOCUMENT_ELEMENT, attributes);
                                XMLUtils.inputStreamToBase64Characters(new BufferedInputStream(content), xmlReceiver);
                                helper.endElement();
                            }
                        }
                        record.skipToEnd();
                        helper.endElement();
                        helper.endElement();
                    }
                    helper.endElement();
                    helper.endDocument();
                } catch (Exception e) {
                    e.printStackTrace();  //To change body of catch statement use File | Settings | File Templates.
                }

            }
        };
        addOutput(outputName, output);
        return output;
    }
}
