/* eslint-disable @lwc/lwc/no-async-operation */
import { LightningElement, track } from "lwc";
import isGuest from "@salesforce/user/isGuest";
const focusableElements =
  "button:not([disabled]), [href], input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex='-1'])";
export default class Lseg_dynamicFormMainModal extends LightningElement {
  @track onSubmitLoad = false;
  @track guestUser = isGuest;
  @track registrationPage = false;
  @track modalFocusAnnouncement = false;
  @track firstFocusedOnModal = false;
  get authenticatePage() {
    return this.guestUser;
  }
  get unAuthenticatePage() {
    return !this.guestUser;
  }
  handleModalClose(event) {
    event.preventDefault();
    document.documentElement.style.overflow = "auto";
    console.log("modal closed");
  }
  setFocusToModal() {
    if (!this.firstFocusedOnModal) {
      let interval = setInterval(() => {
        const modalHeading = this.template.querySelector(".modal-content");
        if (modalHeading) {
          let allFocusableElements = [
            ...modalHeading.querySelectorAll(focusableElements)
          ];
          if (allFocusableElements.length > 0) {
            allFocusableElements[0].focus();
            this.firstFocusedOnModal = true;
            setTimeout(() => {
              this.announceModal();
            }, 500);
            clearInterval(interval);
          }
        }
      }, 100);
    }
  }

  announceModal() {
    if (!this.modalFocusAnnouncement) {
      let interval = setInterval(() => {
        const announcement = this.template.querySelector("#modal-announce");
        if (announcement) {
          announcement.textContent =
            "You have entered the modal. Please use the tab key to navigate through the modal.";
          announcement.focus();
          this.modalFocusAnnouncement = true;
          clearInterval(interval);
        }
      }, 100);
    }
  }

  focusTrappingHandler = (event) => {
    if (event.key === "Escape" || event.keyCode === 27) {
      this.handleModalClose(event);
      return;
    }
    let childElements = [];
    const arr = this.template.querySelector(".modal-content");
    if (arr) {
      let allFocusableElements = arr.querySelectorAll(focusableElements);
    }
  };

  handleRegister() {
    this.firstFocusedOnModal = false;
    this.setFocusToModal();
    console.log("handleRegister called");
    this.registrationPage = true;
    this.announceModal();
  }
}
