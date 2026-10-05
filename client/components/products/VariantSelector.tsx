"use client";

import { ProductVariantDto } from "../../lib/types/product";
import styles from "./VariantSelector.module.css";

interface VariantSelectorProps {
  attributes: string[];
  variants: ProductVariantDto[];
  selectedVariant: ProductVariantDto | null;
  onVariantChange: (variant: ProductVariantDto | null) => void;
}

export default function VariantSelector({
  attributes,
  variants,
  selectedVariant,
  onVariantChange,
}: VariantSelectorProps) {
  const currentAttributes = selectedVariant?.attributes || {};

  const handleSelect = (attrName: string, value: string) => {
    const nextSelection = { ...currentAttributes, [attrName]: value };

    // Find variant matching all selected attributes
    const match = variants.find((v) => {
      return Object.entries(nextSelection).every(
        ([key, val]) => v.attributes[key] === val
      );
    });

    onVariantChange(match || null);
  };

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

  return (
    <div className={styles.container}>
      {attributes.map((attrName) => {
        const values = getValuesForAttribute(attrName);
        const currentValue = currentAttributes[attrName];

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

                // Check if any variant with this option is in stock
                const hasStock = variants.some((v) => {
                  const testSelection = { ...currentAttributes, [attrName]: val };
                  return (
                    v.attributes[attrName] === val &&
                    v.stockQuantity > 0 &&
                    Object.entries(testSelection).every(
                      ([k, vVal]) =>
                        k === attrName ||
                        !v.attributes[k] ||
                        v.attributes[k] === vVal
                    )
                  );
                });

                return (
                  <button
                    key={val}
                    type="button"
                    className={`${styles.optionButton} ${
                      isSelected ? styles.optionSelected : ""
                    } ${!hasStock ? styles.optionDisabled : ""}`}
                    onClick={() => handleSelect(attrName, val)}
                  >
                    {val}
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
