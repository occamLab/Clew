//finds all of the collapseable elements in the menu
var coll = document.getElementsByClassName("collapsible");
//creates an index counter variable
var i;

//updates the accessability labels
function updateAccessabilityLabels (htmlElement,action){
    //if the user just opened a section
    if (action == "open"){
        //set the accessability label
        htmlElement.setAttribute("aria-Label","contract " + htmlElement.innerHTML + " section");
        return 0
    }
    //if the user is closing the section
    if (action == "close"){
        //set the accessability label
        htmlElement.setAttribute("aria-Label","expand " + htmlElement.innerHTML + " section");
        return 0
    }

}


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
