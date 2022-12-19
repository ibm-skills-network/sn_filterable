document.addEventListener("alpine:init", () => {
  Alpine.data("filteringSearchInput", (searchKey) => ({
    currentTimeout: null,
    hasValue: false,
    onInit: function () {
      this.onValueUpdate()
    },
    onUpdate: function (force) {
      this.clearTimeout();
      this.onValueUpdate();

      this.$data.currentTimeout = setTimeout(() => {
        this.$data.currentTimeout = null;

        this.$data.filteringForm.requestSubmit();
      }, force ? 0 : 500);
    },
    onValueUpdate: function () {
      this.$data.hasValue = this.$el.value.length > 0;
    },
    clearTimeout: function () {
      if (this.$data.currentTimeout != null) {
        clearInterval(this.$data.currentTimeout);
        this.$data.currentTimeout = null;
      }
    }
  }));
  Alpine.data("filteringChipContainer", () => ({
    updateSidebarGap: function () {
      this.$data.sidebarGapTarget.style.paddingTop = `${this.$el.clientHeight}px`;
    }
  }));
  Alpine.data("filteringChip", (filter) => ({
    onClick: function (chipElem) {
      const inputElem = this.$data.filteringForm.querySelector(`input[data-filter-name=${JSON.stringify(filter.parent)}][value=${JSON.stringify(filter.value)}]`);
      if (filter.multi) {
        inputElem.click()
      } else {
        inputElem.checked = false;
        this.$data.filteringForm.requestSubmit();
      }

      if (this.$el.closest(".app-filter-chips-container").children.length == 1) {
        this.$el.closest(".app-filter-chips-content").remove();
      } else {
        this.$el.closest(".app-filter-chip").remove();
      }

      this.$data.updateSidebarGap();
    }
  }));
  Alpine.data("filteringClear", (filter) => ({
    onClick: function (chipElem) {
      const chips = Array.from(this.$data.entireComponenet.querySelector(".app-filter-chips-container").querySelectorAll(".app-filter-chip"));

      for (const chip of chips) {
        chip.querySelector("a").click();
      }

      this.$el.closest(".app-filter-chips-content").remove();
    }
  }));
});
