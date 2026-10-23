"use client";

import { useEffect, useState } from "react";
import { ProductVariantDto } from "../../lib/types/product";
import styles from "./VariantSelector.module.css";

interface VariantSelectorProps {
  attributes: string[];
  variants: ProductVariantDto[];
  selectedVariant: ProductVariantDto | null;
  onVariantChange: (variant: ProductVariantDto | null) => void;
  onAttributesChange?: (selectedAttrs: Record<string, string>) => void;
}

export default function VariantSelector({
  attributes,
  variants,
  selectedVariant,
  onVariantChange,
  onAttributesChange,
}: VariantSelectorProps) {
  const [selectedAttrs, setSelectedAttrs] = useState<Record<string, string>>(() => {
    return selectedVariant?.attributes ? { ...selectedVariant.attributes } : {};
  });

  // Sync internal selectedAttrs when selectedVariant is set from parent
  useEffect(() => {
    if (selectedVariant) {
      setSelectedAttrs({ ...selectedVariant.attributes });
    }
  }, [selectedVariant]);

  // Handle case where product has multiple variants but no variantAttributes list
  if (attributes.length === 0 && variants.length > 1) {
    return (
      <div className={styles.container}>
        <div className={styles.attributeGroup}>
          <div className={styles.attributeLabel}>
            <span>Phiên bản:</span>
            <span className={styles.selectedValue}>
              {selectedVariant?.variantName || "Chưa chọn"}
            </span>
          </div>

          <div className={styles.optionsList}>
            {variants.map((v) => {
              const isSelected = selectedVariant?.variantId === v.variantId;
              const hasStock = v.isActive && v.stockQuantity > 0;

              return (
                <button
                  key={v.variantId}
                  type="button"
                  disabled={!hasStock}
                  className={`${styles.optionButton} ${
                    isSelected ? styles.optionSelected : ""
                  } ${!hasStock ? styles.optionDisabled : ""}`}
                  onClick={() => {
                    const next = isSelected ? null : v;
                    onVariantChange(next);
                    if (onAttributesChange) {
                      onAttributesChange(next?.attributes || {});
                    }
                  }}
                  title={!hasStock ? "Tạm hết hàng" : v.variantName}
                >
                  {v.variantName}
                  {!hasStock && (
                    <span className={styles.outOfStockTag}> (Hết)</span>
                  )}
                </button>
              );
            })}
          </div>
        </div>
      </div>
    );
  }

  // Extract all unique values for each attribute name
  const getValuesForAttribute = (attrName: string): string[] => {
    const values = new Set<string>();
    variants.forEach((v) => {
      if (v.attributes && v.attributes[attrName]) {
        values.add(v.attributes[attrName]);
      }
    });
    return Array.from(values);
  };

  const handleSelect = (attrName: string, value: string) => {
    const isCurrentlySelected = selectedAttrs[attrName] === value;
    let nextSelection: Record<string, string>;

    if (isCurrentlySelected) {
      // Toggle off / deselect
      nextSelection = { ...selectedAttrs };
      delete nextSelection[attrName];
    } else {
      // Select new value
      nextSelection = { ...selectedAttrs, [attrName]: value };

      // Re-validate other previously chosen attributes to ensure a compatible variant exists
      for (const otherAttr of attributes) {
        if (otherAttr === attrName) continue;
        const otherVal = nextSelection[otherAttr];
        if (otherVal) {
          const comboExists = variants.some(
            (v) =>
              v.isActive &&
              v.attributes[attrName] === value &&
              v.attributes[otherAttr] === otherVal
          );
          if (!comboExists) {
            delete nextSelection[otherAttr];
          }
        }
      }
    }

    setSelectedAttrs(nextSelection);
    if (onAttributesChange) {
      onAttributesChange(nextSelection);
    }

    // Check if ALL attributes are selected
    const allSelected =
      attributes.length > 0 &&
      attributes.every((attr) => Boolean(nextSelection[attr]));

    if (allSelected) {
      const match = variants.find(
        (v) =>
          v.isActive &&
          attributes.every((attr) => v.attributes[attr] === nextSelection[attr])
      );
      onVariantChange(match || null);
    } else {
      // Partial or no selection -> no variant chosen
      onVariantChange(null);
    }
  };

  return (
    <div className={styles.container}>
      {attributes.map((attrName) => {
        const values = getValuesForAttribute(attrName);
        const currentValue = selectedAttrs[attrName];

        return (
          <div key={attrName} className={styles.attributeGroup}>
            <div className={styles.attributeLabel}>
              <span>{attrName}:</span>
              <span className={styles.selectedValue}>
                {currentValue || "Chưa chọn"}
              </span>
            </div>

            <div className={styles.optionsList}>
              {values.map((val) => {
                const isSelected = currentValue === val;

                // 1. Check if any active variant has this attribute value at all
                const existsAny = variants.some(
                  (v) => v.isActive && v.attributes[attrName] === val
                );

                // 2. Check compatibility with OTHER currently selected attributes
                const otherEntries = Object.entries(selectedAttrs).filter(
                  ([k]) => k !== attrName
                );

                const matchingVariants = variants.filter(
                  (v) =>
                    v.isActive &&
                    v.attributes[attrName] === val &&
                    otherEntries.every(([k, vVal]) => v.attributes[k] === vVal)
                );

                const isCompatible =
                  existsAny && (otherEntries.length === 0 || matchingVariants.length > 0);

                const hasStock = matchingVariants.some(
                  (v) => v.stockQuantity > 0
                );

                const isDisabled = !isCompatible || (!isSelected && !hasStock);

                return (
                  <button
                    key={val}
                    type="button"
                    disabled={isDisabled}
                    className={`${styles.optionButton} ${
                      isSelected ? styles.optionSelected : ""
                    } ${isDisabled ? styles.optionDisabled : ""}`}
                    onClick={() => handleSelect(attrName, val)}
                    title={
                      !isCompatible
                        ? "Không khả dụng với lựa chọn hiện tại"
                        : !hasStock
                          ? "Tạm hết hàng"
                          : val
                    }
                  >
                    {val}
                    {isCompatible && !hasStock && (
                      <span className={styles.outOfStockTag}> (Hết)</span>
                    )}
                  </button>
                );
              })}
            </div>
          </div>
        );
      })}
    </div>
  );
}
