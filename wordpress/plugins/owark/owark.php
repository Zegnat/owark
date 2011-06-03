<?php
/*  Copyright 2011 Eric van der Vlist (vdv@dyomedea.com)

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License, version 2, as 
    published by the Free Software Foundation.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/

/*
Plugin Name: owark
Plugin URI: http://owark.org
Description: Tired of broken links? Archive yours with owark, the Open Web Archive!
Version: 0.1
Author: Eric van der Vlist
Author URI: http://eric.van-der-vlist.com
License: GLP2
*/


if (!class_exists("Owark")) {
	class Owark {

        private $broken_links = array();
        private $post_id = -1;
        private $post_type = "";
        private $version = '0.1';
        
        /**
         * Class constructor
         *
         * @package owark
         * @since 0.1
         *
         *
         */
		function Owark() {


            if (is_admin()) {
                add_action('admin_menu', array($this, 'owark_admin_menu'));
                add_action('plugins_loaded', array($this, 'sanity_checks'));
            }

            // See http://stackoverflow.com/questions/2210826/need-help-with-wp-rewrite-in-a-wordpress-plugin
            // Using a filter instead of an action to create the rewrite rules.
            // Write rules -> Add query vars -> Recalculate rewrite rules
            add_filter('rewrite_rules_array', array($this, 'create_rewrite_rules'));
            add_filter('query_vars',array($this, 'add_query_vars'));

            // Recalculates rewrite rules during admin init to save resources.
            // Could probably run it once as long as it isn't going to change or check the
            // $wp_rewrite rules to see if it's active.
            add_filter('admin_init', array($this, 'flush_rewrite_rules'));
            add_action( 'template_redirect', array($this, 'template_redirect_intercept') );

            add_filter ( 'the_content', array($this, 'content_filter'));
            add_filter ( 'comment_text', array($this, 'comment_filter'));
            add_filter ( 'get_comment_author_link', array($this, 'comment_filter'));

		}

        /**
         * Check we have everything we need...
         *
         * @package owark
         * @since 0.1
         *
         *
         */
        function sanity_checks(){
            $installed_ver = get_option( "owark_db_version" );
            if ($installed_ver != $this->version) {
                global $wpdb;
                $table = $wpdb->prefix."owark";
                $sql = "CREATE TABLE $table (
                    id int(10) unsigned NOT NULL AUTO_INCREMENT,
                    url text NOT NULL,
                    status varchar(20) NOT NULL DEFAULT 'to-archive',
                    arc_date datetime,
                    arc_location text,
                    PRIMARY KEY(`id`),
                    KEY `url` (`url`(150)) )";
                require_once(ABSPATH . 'wp-admin/includes/upgrade.php');
                dbDelta($sql);

                update_option( "owark_db_version", $this->version );

            }
        }

        /**
         * Admin menus
         *
         * @package owark
         * @since 0.1
         *
         *
         */
        function owark_admin_menu() {
            add_management_page(__('The Open Web Archive', 'owark'), __('Web Archive', 'owark'), 'edit_others_posts', 'owark', array($this, 'management_page'));
        }

        /**
         * URL of an archive page
         *
         * @package owark
         * @since 0.1
         *
         *
         */
        function get_archive_url($archive_id) {
            return home_url().'/owark/'.$archive_id;
        }

        /**
         * Display the admin/tools page.
         *
         * @package owark
         * @since 0.1
         *
         *
         */
        function management_page() {
            //must check that the user has the required capability
            if (!current_user_can('edit_others_posts')) {
                wp_die( __('You do not have sufficient permissions to access this page.') );
            }

            global $wpdb;

            echo '<div class="wrap">';
            screen_icon();
            echo '<h2>Owark - The Open Web Archive</h2>';
            echo '<p><em>Tired of broken links? Archive yours with the Open Web Archive!</em></p>';
            echo "</div>";

            echo '<p>List of broken links with successfully archived pages:</p>';

            $query = "SELECT owark.id, owark.url, owark.status, owark.arc_date, owark.arc_location, blc_links.status_text
                        FROM {$wpdb->prefix}owark AS owark, {$wpdb->prefix}blc_links as blc_links
                        WHERE owark.url = blc_links.final_url COLLATE latin1_swedish_ci and blc_links.broken = 1
                        ORDER BY owark.url";
            $results = $wpdb->get_results($query);

            echo '<table class="widefat">';
            echo '<thead>';
            echo '<tr>';
            echo '<th>URL</th>';
            echo '<th>Archive</th>';
            echo '</tr>';
            echo '</thead>';
            echo '<tbody>';

            foreach ($results as $link) {
                $archive_url = $this->get_archive_url($link->id);
                echo "<tr>
                        <td><a href=\"{$link->url}\" target='_blank'>{$link->url}</a></td>
                        <td><a href=\"{$archive_url}\" target='_blank'>{$link->arc_date}</a></td>
                    </tr>";
            }

            echo '</tbody>';
            echo '</table>';


        }

        /**
         * Add a rewrite rule to display archive pages
         *
         * @package owark
         * @since 0.1
         *
         *
         */
        function create_rewrite_rules($rules) {
            global $wp_rewrite;
            $newRule = array('owark/(.+)' => 'index.php?owark='.$wp_rewrite->preg_index(1));
            $newRules = $newRule + $rules;
            return $newRules;
        }

        /**
         * Add a query variable used to display archive pages
         *
         * @package owark
         * @since 0.1
         *
         *
         */
        function add_query_vars($qvars) {
            $qvars[] = 'owark';
            return $qvars;
        }

        /**
         * Title says it all ;) ...
         *
         * @package owark
         * @since 0.1
         *
         *
         */
        function flush_rewrite_rules() {
            global $wp_rewrite;
            $wp_rewrite->flush_rules();
        }

        /**
         * Intercepts archive pages.
         *
         * @package owark
         * @since 0.1
         *
         *
         */
        function template_redirect_intercept() {
            global $wp_query;
            if ($wp_query->get('owark')) {
                $this->display_archive($wp_query->get('owark'));
                exit;
            }
        }

        /**
         * Filter to replace broken links in comments.
         *
         * @package owark
         * @since 0.1
         *
         *
         */
        function content_filter($content) {
            global $post;
            return $this->link_filter($content, $post->ID, $post->post_type);
        }

        /**
         * Filter to replace broken links in comments.
         *
         * @package owark
         * @since 0.1
         *
         *
         */
        function comment_filter($content) {
            return $this->link_filter($content, get_comment_ID(), 'comment');
        }

        /**
         * Generic filter to replace broken links in content.
         *
         * @package owark
         * @since 0.1
         *
         *
         */
        function link_filter($content, $post_id, $post_type) {

            global $wpdb;

            // See if we haven't already loaded the broken links for this post...
            if ($this->post_id != $post_id || $this->post_type != $post_type) {

                $this->post_id =  $post_id;
                $this->post_type = $post_type;

                //Retrieve info about all occurrences of broken links in the current post
                //which happens for comments (they have links to check in 2 different filters)
                $q = "
                    SELECT instances.raw_url, owark.id
                    FROM {$wpdb->prefix}blc_instances AS instances,
                        {$wpdb->prefix}blc_links AS links,
                        {$wpdb->prefix}owark AS owark
                    WHERE
                        instances.link_id = links.link_id
                        AND owark.url = links.final_url COLLATE latin1_swedish_ci
                        AND instances.container_id = %s
                        AND instances.container_type = %s
                        AND links.broken = 1
                ";
                $q = $wpdb->prepare($q, $this->post_id, $this->post_type);
                $results = $wpdb->get_results($q);

                $this->broken_links = array();

                foreach ($results as $link) {
                    $this->broken_links[$link->raw_url] = $link->id;
                }

            }


            if (empty($this->broken_links)) {
                return $content;
            }

            // Regexp : see http://stackoverflow.com/questions/2609095/hooking-into-comment-text-to-add-surrounding-tag
            return preg_replace_callback('/(<a.*?href\s*=\s*["\'])([^"\'>]+)(["\'][^>]*>.*?<\/a>)/si', array( $this, 'replace_a_link'), $content);
        }

        /**
         * Replace a link.
         *
         * @package owark
         * @since 0.1
         *
         *
         */
        function replace_a_link($matches) {
            if (array_key_exists($matches[2], $this->broken_links)) {
                return $matches[1].$this->get_archive_url($this->broken_links[$matches[2]]).$matches[3];
            } else {
                return $matches[0];
            }
        }


        /**
         * Display an archive page
         *
         * @package owark
         * @since 0.1
         *
         *
         */
        function display_archive($parameter) {

            global $wpdb;

            $id = intval($parameter);

            $query = "SELECT *
                        from {$wpdb->prefix}owark AS owark
                        where id = {$id}";
            $link = $wpdb->get_row($query);

            $blog_title = get_bloginfo('name');
            $home_url = home_url();

            $loc = "";
            if( ($pos = strpos($link->arc_location, '/wp-content/perwac/')) !== FALSE )
                $loc = substr($link->arc_location, $pos);
            $arc_loc = home_url() . $loc;

            echo '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
        "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">';

            echo "<base href=\"{$arc_loc}/\">";
            echo '<div style="background:#fff;border:1px solid #999;margin:-1px -1px 0;padding:0;">';
            echo '<div style="background:#ddd;border:1px solid #999;color:#000;font:13px arial,sans-serif;font-weight:normal;margin:12px;padding:8px;text-align:left">';
            echo "This is an <a href='http://owark.org'>Open Web Archive</a> archive of <a href=\"{$link->url}\">{$link->url}</a>.";
            echo "<br />This snapshot has been taken on {$link->arc_date} for the website <a href=\"{$home_url}\">{$blog_title}</a> which contains a link to this page and has saved a copy to be displayed in the page ever disappears.";
            echo '</div></div><div style="position:relative">';
            $file_location = '.'.$loc.'/index.html';
            $f = fopen($file_location, "r");
            echo fread($f, filesize($file_location));
            fclose($f);
            echo '</div>';
        }


	}
}


if (class_exists("Owark")) {
	$owark = new Owark();
}



?>
