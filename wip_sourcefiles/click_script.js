var linkEl = $( 'link selector' );
if ( linkEl.attr ( 'onclick' ) === undefined ) {
    document.location = linkEl.attr ( 'href' );
} else {
    linkEl.click ();
}

//
//selector = element id for bestemt fane

$( 'selector for your link' ).click ();