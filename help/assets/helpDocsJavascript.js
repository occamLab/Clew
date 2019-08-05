var tut = document.getElementsByClassName("tutorial");
//finds all of the collapseable elements in the menu
var coll = document.getElementsByClassName("collapsible");
//creates an index counter variable
var i;

tut[0].addEventListener("click", function() {
                        // TODO: dismiss popover and pull up tutorial
                        });

//itterates through all of the collapseable elements
for (i = 0; i < coll.length; i++) {
//adds clickable functionality
coll[i].addEventListener("click", function() {
                         //toggles the active state of the collapseable element
                         this.classList.toggle("active");
                         //grabs a reference to the content
                         var content = this.nextElementSibling;
                         //if the content is displayed
                         if (content.style.display === "block") {
                         //hide the content
                         content.style.display = "none";
                         //change the accessability tag
                         updateAccessabilityLabels(this,"close");
                         
                         } else {
                         //show the content
                         content.style.display = "block";
                         //change the accessability tag
                         updateAccessabilityLabels(this,"open");
                         }
                         });
}
